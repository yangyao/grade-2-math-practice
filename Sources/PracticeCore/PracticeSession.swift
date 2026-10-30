import Foundation

public struct QuestionPart: Codable, Sendable {
    public var text: String?
    public var blank: Int?
}

public struct Question: Codable, Identifiable, Sendable {
    public var number: Int
    public var id: Int
    public var lines: [[QuestionPart]]
    public var answers: [String]
    public var plainText: String {
        lines.map { $0.map { $0.text ?? "____" }.joined() }.joined(separator: " ")
    }
}

public struct PracticeRecord: Codable, Identifiable, Sendable {
    public var id = UUID()
    public var date: Date
    public var seconds: TimeInterval
    public var correct: Int
    public var total: Int
    public var mistakes: [Question]?
    public var isReview: Bool?
    public var isPerfect: Bool { correct == total }
    public var wrongCount: Int { max(0, total - correct) }
    public var isReviewPractice: Bool { isReview == true }
    public var canReview: Bool {
        guard let mistakes else { return false }
        return wrongCount > 0 && mistakes.count == wrongCount && Set(mistakes.map(\.id)).count == wrongCount
    }
}

public struct PracticeSession: Codable, Sendable {
    public var index = 0
    public var activeBlank = 0
    public var answers: [[String]]
    public var startedAt: Date?
    public var finishedAt: Date?
    public var isNewRecord = false

    public init(questions: [Question]) {
        answers = questions.map { Array(repeating: "", count: $0.answers.count) }
    }

    public func elapsed(at now: Date = Date()) -> TimeInterval {
        guard let startedAt else { return 0 }
        return max(0, (finishedAt ?? now).timeIntervalSince(startedAt))
    }
    public func isComplete(_ index: Int) -> Bool { answers[index].allSatisfy { !$0.isEmpty } }
    public var completedCount: Int { answers.indices.filter { isComplete($0) }.count }
    public func isCorrect(_ index: Int, questions: [Question]) -> Bool { answers[index] == questions[index].answers }
    public func correctCount(questions: [Question]) -> Int { answers.indices.filter { isCorrect($0, questions: questions) }.count }

    public func isValid(questions: [Question]) -> Bool {
        guard questions.indices.contains(index), questions[index].answers.indices.contains(activeBlank), answers.count == questions.count else { return false }
        guard answers.enumerated().allSatisfy({ i, row in
            row.count == questions[i].answers.count && row.allSatisfy { $0.count <= 3 && $0.allSatisfy { "0123456789<>=".contains($0) } }
        }) else { return false }
        if let start = startedAt, start > Date() { return false }
        if let finish = finishedAt {
            guard let start = startedAt, finish >= start, finish <= Date(), completedCount == questions.count else { return false }
        }
        return true
    }

    public mutating func navigate(to target: Int, questions: [Question]) {
        guard questions.indices.contains(target), finishedAt == nil else { return }
        index = target
        activeBlank = answers[target].firstIndex(of: "") ?? 0
    }

    @discardableResult
    public mutating func input(_ key: String, questions: [Question], now: Date = Date()) -> Bool {
        guard finishedAt == nil else { return false }
        let comparison = ["<", ">", "="].contains(questions[index].answers[activeBlank])
        var value = answers[index][activeBlank]
        if key == "delete" { if !value.isEmpty { value.removeLast() } }
        else if key == "clear" { value = "" }
        else if comparison && ["<", ">", "="].contains(key) { value = key; startedAt = startedAt ?? now }
        else if !comparison && key.count == 1 && "0123456789".contains(key) {
            guard value.count < 3 else { return false }
            value = value == "0" ? key : value + key
            startedAt = startedAt ?? now
        } else { return false }
        answers[index][activeBlank] = value
        return true
    }

    public enum Advance: Equatable { case empty, moved, unfinished(Int), finished }
    public mutating func advance(questions: [Question], now: Date = Date()) -> Advance {
        guard finishedAt == nil else { return .finished }
        guard !answers[index][activeBlank].isEmpty else { return .empty }
        if activeBlank < answers[index].count - 1 { activeBlank += 1; return .moved }
        if index < questions.count - 1 { navigate(to: index + 1, questions: questions); return .moved }
        if let missing = answers.indices.first(where: { !isComplete($0) }) {
            navigate(to: missing, questions: questions); return .unfinished(missing)
        }
        finishedAt = now
        return .finished
    }
}

public struct PracticeArchive: Codable, Sendable {
    public var version = 1
    public var session: PracticeSession
    public var records: [PracticeRecord]
    public var reviewQuestions: [Question]?
    public var suspendedSession: PracticeSession?
    public init(session: PracticeSession, records: [PracticeRecord]) { self.session = session; self.records = records }
    public var best: PracticeRecord? { records.filter { $0.isPerfect && !$0.isReviewPractice }.min { $0.seconds < $1.seconds } }
    public mutating func addRecord(questions: [Question]) {
        guard let finish = session.finishedAt else { return }
        let wrong = questions.indices.filter { !session.isCorrect($0, questions: questions) }.map { questions[$0] }
        let record = PracticeRecord(date: finish, seconds: session.elapsed(), correct: session.correctCount(questions: questions), total: questions.count, mistakes: wrong, isReview: reviewQuestions != nil)
        session.isNewRecord = !record.isReviewPractice && record.isPerfect && (best == nil || record.seconds < best!.seconds)
        records.insert(record, at: 0)
        let allTimeBest = best
        records = Array(records.prefix(50))
        if let allTimeBest, !records.contains(where: { $0.id == allTimeBest.id }) { records[records.count - 1] = allTimeBest }
    }

    @discardableResult
    public mutating func beginReview(_ record: PracticeRecord) -> Bool {
        guard record.canReview, let mistakes = record.mistakes else { return false }
        if reviewQuestions == nil { suspendedSession = session }
        reviewQuestions = mistakes
        session = PracticeSession(questions: mistakes)
        return true
    }

    public mutating func endReview(questions: [Question]) {
        guard reviewQuestions != nil else { return }
        session = suspendedSession.flatMap { $0.isValid(questions: questions) ? $0 : nil } ?? PracticeSession(questions: questions)
        reviewQuestions = nil
        suspendedSession = nil
    }

    // Older archives retain answers for the current finished round only.
    // Recover that one record when it matches exactly; never invent older mistakes.
    public mutating func recoverCurrentMistakes(questions: [Question]) {
        guard let finish = session.finishedAt,
              let i = records.firstIndex(where: { $0.date == finish && $0.total == questions.count && $0.correct == session.correctCount(questions: questions) }),
              records[i].mistakes == nil else { return }
        records[i].mistakes = questions.indices.filter { !session.isCorrect($0, questions: questions) }.map { questions[$0] }
    }
}
