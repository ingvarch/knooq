import Foundation
@testable import KnooqKit

/// Test doubles for the non-deterministic dependencies. Live in the test target only —
/// the production framework never ships stubs (YAGNI).

final class StubAnalyzer: Analyzer, @unchecked Sendable {
    var result: ItemAnalysis?
    var error: Error?
    private(set) var receivedText: String?

    func analyze(_ text: String) async throws -> ItemAnalysis {
        receivedText = text
        if let error { throw error }
        return result ?? ItemAnalysis(category: .other, tags: [], title: "Stub", summary: "Stub")
    }
}

final class StubTextExtractor: TextExtractor, @unchecked Sendable {
    var text: String = ""
    var error: Error?

    func extract(from payload: RawPayload) async throws -> String {
        if let error { throw error }
        return text
    }
}

final class StubNotifier: Notifier, @unchecked Sendable {
    private(set) var scheduled: [NudgeNotification] = []
    private(set) var cancelledCount = 0

    func schedule(_ notification: NudgeNotification) async throws {
        scheduled.append(notification)
    }

    func cancelAll() async {
        cancelledCount += 1
    }
}

final class StubDateProvider: DateProvider, @unchecked Sendable {
    var fixedDate: Date
    init(_ date: Date) { self.fixedDate = date }
    var now: Date { fixedDate }
}
