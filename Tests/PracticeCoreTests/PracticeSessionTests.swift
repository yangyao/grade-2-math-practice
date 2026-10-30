import XCTest
@testable import PracticeCore

final class PracticeSessionTests: XCTestCase {
    func testCompleteRealHundredQuestionSet() throws {
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: package.appendingPathComponent("Sources/MentalMathGlass/Resources/questions.json"))
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
