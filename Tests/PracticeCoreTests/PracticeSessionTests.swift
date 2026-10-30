import XCTest
@testable import PracticeCore

final class PracticeSessionTests: XCTestCase {
    func testWrongQuestionReviewAndReturnToFullSession() throws {
        let qs = try questions()
        var session = PracticeSession(questions: qs)
        session.answers = [["8"], ["12", "4"], ["="]]
        session.startedAt = Date(timeIntervalSince1970: 1000)
        session.finishedAt = Date(timeIntervalSince1970: 1040)
        var archive = PracticeArchive(session: session, records: [])
        archive.addRecord(questions: qs)
        let original = archive.records[0]
        XCTAssertEqual(original.wrongCount, 2)
        XCTAssertEqual(original.mistakes?.map(\.id), [1, 2])
        XCTAssertTrue(original.canReview)
        XCTAssertTrue(archive.beginReview(original))
        let review = try XCTUnwrap(archive.reviewQuestions)
        XCTAssertEqual(archive.session.answers, [[""], ["", ""]])
        archive.session.answers = review.map(\.answers)
        archive.session.startedAt = Date(timeIntervalSince1970: 1050)
        archive.session.finishedAt = Date(timeIntervalSince1970: 1053)
        archive.addRecord(questions: review)
        XCTAssertTrue(archive.records[0].isReviewPractice)
        XCTAssertEqual(archive.records[0].wrongCount, 0)
        XCTAssertFalse(archive.records[0].canReview)
        XCTAssertNil(archive.best)
        XCTAssertFalse(archive.session.isNewRecord)
        let saved = try JSONDecoder().decode(PracticeArchive.self, from: JSONEncoder().encode(archive))
        archive = saved
        archive.endReview(questions: qs)
        XCTAssertNil(archive.reviewQuestions)
        XCTAssertEqual(archive.session.answers, session.answers)
        XCTAssertEqual(archive.session.finishedAt, session.finishedAt)
    }

    func testLegacyRecordsAndRecoverableLastRound() throws {
        let qs = try questions()
        var session = PracticeSession(questions: qs)
        session.answers = [["8"], ["12", "3"], ["="]]
        session.startedAt = Date(timeIntervalSince1970: 1000)
        session.finishedAt = Date(timeIntervalSince1970: 1040)
        var archive = PracticeArchive(session: session, records: [])
        archive.addRecord(questions: qs)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(archive)) as? [String: Any])
        var rows = try XCTUnwrap(object["records"] as? [[String: Any]])
        rows[0].removeValue(forKey: "mistakes")
        rows[0].removeValue(forKey: "isReview")
        object["records"] = rows
        object.removeValue(forKey: "reviewQuestions")
        object.removeValue(forKey: "suspendedSession")
        archive = try JSONDecoder().decode(PracticeArchive.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(archive.records[0].wrongCount, 1)
        XCTAssertFalse(archive.records[0].canReview)
        XCTAssertFalse(archive.beginReview(archive.records[0]))
        archive.recoverCurrentMistakes(questions: qs)
        XCTAssertTrue(archive.records[0].canReview)
        XCTAssertEqual(archive.records[0].mistakes?.map(\.id), [1])
    }

    func testSwitchingReviewDoesNotReplaceSuspendedProgress() throws {
        let qs = try questions()
        var archive = PracticeArchive(session: PracticeSession(questions: qs), records: [])
        archive.session.answers = [["8"], ["12", "3"], ["<"]]
        archive.session.startedAt = Date(timeIntervalSince1970: 1000)
        archive.session.finishedAt = Date(timeIntervalSince1970: 1050)
        archive.addRecord(questions: qs)
        let source = archive.records[0]
        archive.session = PracticeSession(questions: qs)
        archive.session.input("9", questions: qs)
        XCTAssertTrue(archive.beginReview(source))
        XCTAssertTrue(archive.beginReview(source))
        archive.endReview(questions: qs)
        XCTAssertEqual(archive.session.answers[0], ["9"])
        XCTAssertNil(archive.session.finishedAt)
    }
    func testCompleteRealHundredQuestionSet() throws {
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: package.appendingPathComponent("Sources/Grade2MathPractice/Resources/questions.json"))
        let qs = try JSONDecoder().decode([Question].self, from: data)
        XCTAssertEqual(qs.count, 100)
        var session = PracticeSession(questions: qs)
        let start = Date(timeIntervalSince1970: 1000)
        var tick = 0.0
        for (index, q) in qs.enumerated() {
            XCTAssertEqual(session.index, index)
            XCTAssertEqual(q.lines.flatMap { $0 }.compactMap(\.blank).sorted(), Array(q.answers.indices))
            for (blank, answer) in q.answers.enumerated() {
                XCTAssertEqual(session.activeBlank, blank)
                for character in answer {
                    XCTAssertTrue(session.input(String(character), questions: qs, now: start.addingTimeInterval(tick)))
                    tick += 1
                }
                let outcome = session.advance(questions: qs, now: start.addingTimeInterval(tick))
                XCTAssertEqual(outcome, index == 99 && blank == q.answers.count - 1 ? .finished : .moved)
            }
        }
        XCTAssertEqual(session.completedCount, 100)
        XCTAssertEqual(session.correctCount(questions: qs), 100)
        XCTAssertEqual(session.elapsed(), tick)
    }
    private func questions() throws -> [Question] {
        try JSONDecoder().decode([Question].self, from: Data("""
        [{"number":1,"id":1,"lines":[[{"text":"15-6="},{"blank":0}]],"answers":["9"]},
         {"number":2,"id":2,"lines":[[{"text":"9+3="},{"blank":0}],[{"text":"12-9="},{"blank":1}]],"answers":["12","3"]},
         {"number":3,"id":3,"lines":[[{"text":"13-9"},{"blank":0},{"text":"4"}]],"answers":["="]}]
        """.utf8))
    }
    func testTimerBlankValidationAndCompletion() throws {
        let qs = try questions()
        var session = PracticeSession(questions: qs)
        let start = Date(timeIntervalSince1970: 1000)
        XCTAssertEqual(session.advance(questions: qs), .empty)
        XCTAssertNil(session.startedAt)
        XCTAssertFalse(session.input("=", questions: qs, now: start))
        XCTAssertTrue(session.input("9", questions: qs, now: start))
        XCTAssertEqual(session.elapsed(at: start.addingTimeInterval(5)), 5)
        XCTAssertEqual(session.advance(questions: qs), .moved)
        session.input("1", questions: qs)
        session.input("2", questions: qs)
        XCTAssertEqual(session.advance(questions: qs), .moved)
        XCTAssertEqual(session.activeBlank, 1)
        session.input("3", questions: qs)
        XCTAssertEqual(session.advance(questions: qs), .moved)
        XCTAssertFalse(session.input("4", questions: qs))
        session.input("=", questions: qs)
        XCTAssertEqual(session.advance(questions: qs, now: start.addingTimeInterval(20)), .finished)
        XCTAssertEqual(session.correctCount(questions: qs), 3)
        XCTAssertEqual(session.elapsed(at: start.addingTimeInterval(500)), 20)
        XCTAssertFalse(session.input("<", questions: qs))
        let decoded = try JSONDecoder().decode(PracticeSession.self, from: JSONEncoder().encode(session))
        XCTAssertTrue(decoded.isValid(questions: qs))
        XCTAssertEqual(decoded.elapsed(), 20)
    }
    func testSkippedQuestionsReturnToFirstMissingAndEditing() throws {
        let qs = try questions()
        var session = PracticeSession(questions: qs)
        session.navigate(to: 2, questions: qs)
        session.input(">", questions: qs)
        session.input("=", questions: qs)
        XCTAssertEqual(session.answers[2], ["="])
        XCTAssertEqual(session.advance(questions: qs), .unfinished(0))
        XCTAssertNil(session.finishedAt)
        session.input("9", questions: qs)
        session.input("delete", questions: qs)
        XCTAssertEqual(session.answers[0], [""])
        session.input("0", questions: qs)
        session.input("9", questions: qs)
        XCTAssertEqual(session.answers[0], ["9"])
    }
    func testWrongAnswersDoNotBecomeBestAndBestSurvivesHistoryLimit() throws {
        let qs = try questions()
        var session = PracticeSession(questions: qs)
        session.answers = qs.map(\.answers)
        session.startedAt = Date(timeIntervalSince1970: 1000)
        session.finishedAt = Date(timeIntervalSince1970: 1020)
        var archive = PracticeArchive(session: session, records: [])
        archive.addRecord(questions: qs)
        XCTAssertTrue(archive.session.isNewRecord)
        let bestID = archive.best?.id
        archive.session.finishedAt = Date(timeIntervalSince1970: 1001)
        archive.session.answers[0] = ["8"]
        archive.addRecord(questions: qs)
        XCTAssertFalse(archive.session.isNewRecord)
        XCTAssertEqual(archive.best?.seconds, 20)
        archive.session.answers = qs.map(\.answers)
        for index in 0..<55 {
            archive.session.finishedAt = Date(timeIntervalSince1970: Double(1050 + index))
            archive.addRecord(questions: qs)
        }
        XCTAssertEqual(archive.records.count, 50)
        XCTAssertEqual(archive.best?.id, bestID)
        let decoded = try JSONDecoder().decode(PracticeArchive.self, from: JSONEncoder().encode(archive))
        XCTAssertEqual(decoded.best?.id, bestID)
    }
    func testCorruptSessionIsRejected() throws {
        let qs = try questions()
        var session = PracticeSession(questions: qs)
        session.index = 200
        XCTAssertFalse(session.isValid(questions: qs))
        session = PracticeSession(questions: qs)
        session.answers[0] = []
        XCTAssertFalse(session.isValid(questions: qs))
        session = PracticeSession(questions: qs)
        session.finishedAt = .now
        XCTAssertFalse(session.isValid(questions: qs))
    }
}
