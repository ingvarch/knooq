import Testing
import Foundation
@testable import KnooqKit

@Suite struct StubAnalyzerTests {

    @Test func returnsConfiguredResult() async throws {
        let stub = StubAnalyzer()
        stub.result = ItemAnalysis(category: .recipe, tags: ["a"], title: "T", summary: "S")
        let out = try await stub.analyze("text")
        #expect(out.category == .recipe)
        #expect(out.title == "T")
        #expect(stub.receivedText == "text")
    }

    @Test func throwsConfiguredError() async {
        struct Boom: Error {}
        let stub = StubAnalyzer()
        stub.error = Boom()
        await #expect(throws: Boom.self) { try await stub.analyze("x") }
    }
}

@Suite struct StubDateProviderTests {

    @Test func returnsFixedDate() {
        let date = Date(timeIntervalSince1970: 1_000)
        let clock = StubDateProvider(date)
        #expect(clock.now == date)
    }

    @Test func systemDateProviderConforms() {
        let provider: DateProvider = SystemDateProvider()
        #expect(provider.now.timeIntervalSince1970 > 0)
    }
}

@Suite struct RawPayloadTests {

    @Test func mapsFromSavedItem() {
        let item = SavedItem(rawType: .url, rawURL: URL(string: "https://e.com"), rawText: "t", imageFilename: "f.png")
        let payload = RawPayload(item)
        #expect(payload.rawType == .url)
        #expect(payload.rawURL == URL(string: "https://e.com"))
        #expect(payload.rawText == "t")
        #expect(payload.imageFilename == "f.png")
    }
}

@Suite struct NotifierStubTests {

    @Test func recordsScheduledAndCancelled() async throws {
        let notifier = StubNotifier()
        try await notifier.schedule(NudgeNotification(category: .idea, itemCount: 3, message: "m"))
        await notifier.cancelAll()
        #expect(notifier.scheduled.count == 1)
        #expect(notifier.scheduled.first?.category == .idea)
        #expect(notifier.cancelledCount == 1)
    }
}
