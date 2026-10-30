import SwiftUI
#if canImport(PracticeCore)
import PracticeCore
#endif

@MainActor
final class PracticeStore: ObservableObject {
    let allQuestions: [Question]
    var questions: [Question] { archive.reviewQuestions ?? allQuestions }
    var isReview: Bool { archive.reviewQuestions != nil }
    @Published var archive: PracticeArchive
    @Published var notice = ""
    @Published var showingHistory = false
    @Published var confirmingRestart = false
    @Published var persistenceWarning = false
    let storageURL: URL

    init() throws {
        #if SWIFT_PACKAGE
        let resources = Bundle.module
        #else
        let resources = Bundle.main
        #endif
        guard let url = resources.url(forResource: "questions", withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
        let bank = try JSONDecoder().decode([Question].self, from: Data(contentsOf: url))
        allQuestions = bank
        guard !bank.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = base.appendingPathComponent("dev.yangyao.MentalMathGlass", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        storageURL = folder.appendingPathComponent("practice.json")
        if let data = try? Data(contentsOf: storageURL), var saved = try? JSONDecoder().decode(PracticeArchive.self, from: data), saved.version == 1 {
            if let review = saved.reviewQuestions, review.isEmpty || Set(review.map(\.id)).count != review.count || review.contains(where: { $0.answers.isEmpty }) {
                saved.endReview(questions: bank)
            }
            let active = saved.reviewQuestions ?? bank
            if !saved.session.isValid(questions: active) { saved.session = PracticeSession(questions: active) }
            saved.records = saved.records.filter { $0.seconds.isFinite && $0.seconds >= 0 && $0.total > 0 && $0.total <= bank.count && (0...$0.total).contains($0.correct) }
            saved.recoverCurrentMistakes(questions: active)
            archive = saved
        } else { archive = PracticeArchive(session: PracticeSession(questions: bank), records: []) }

    }

    var session: PracticeSession { archive.session }
    var current: Question { questions[session.index] }
    var best: PracticeRecord? { isReview ? nil : archive.best }
    var isFinished: Bool { session.finishedAt != nil }
    var comparison: Bool { ["<", ">", "="].contains(current.answers[session.activeBlank]) }
    var nextLabel: String { session.activeBlank < current.answers.count - 1 ? "下一空" : session.index == questions.count - 1 ? "完成练习" : "下一题" }
    var keyboardEnabled: Bool { !showingHistory && !confirmingRestart && !isFinished }

    func save() {
        do { try JSONEncoder().encode(archive).write(to: storageURL, options: .atomic) }
        catch { persistenceWarning = true }
    }
    func input(_ key: String) {
        guard archive.session.input(key, questions: questions) else { return }
        notice = ""; save()
    }
    func selectBlank(_ blank: Int) { archive.session.activeBlank = blank; notice = ""; save() }
    func navigate(_ index: Int) { archive.session.navigate(to: index, questions: questions); notice = ""; save() }
    func next() {
        guard !isFinished else { return }
        switch archive.session.advance(questions: questions) {
        case .empty: notice = "这里还没填"
        case .unfinished: notice = "还有空格没填"
        case .moved: notice = ""
        case .finished: archive.addRecord(questions: questions); notice = ""
        }
        save()
    }
    func restart() {
        archive.session = PracticeSession(questions: questions)
        notice = ""; confirmingRestart = false; save()
    }
    func requestRestart() { if session.startedAt == nil || isFinished { restart() } else { confirmingRestart = true } }
    func review(_ record: PracticeRecord) {
        guard archive.beginReview(record) else { notice = "这次记录没有保存具体错题"; return }
        showingHistory = false; notice = ""; save()
    }
    func leaveReview() {
        archive.endReview(questions: allQuestions)
        notice = ""; save()
    }
    static func seconds(_ value: TimeInterval) -> String { String(format: "%.1f", value) }
}
