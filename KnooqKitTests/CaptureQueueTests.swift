import Testing
import Foundation
@testable import KnooqKit

@Suite struct CaptureQueueTests {

    private func tempQueue() -> CaptureQueue {
        CaptureQueue(directory: FileManager.default.temporaryDirectory
            .appendingPathComponent("capture-\(UUID().uuidString)"))
    }

    @Test func enqueueThenDrainReturnsCapture() throws {
        let queue = tempQueue()
        try queue.enqueue(PendingCapture(rawType: .url, urlString: "https://e.com",
                                         text: nil, imageFilename: nil, createdAt: Date(timeIntervalSince1970: 1)))
        let drained = try queue.drain()
        #expect(drained.count == 1)
        #expect(drained.first?.rawType == .url)
        #expect(drained.first?.urlString == "https://e.com")
    }

    @Test func drainIsDestructive() throws {
        let queue = tempQueue()
        try queue.enqueue(PendingCapture(rawType: .text, urlString: nil, text: "hi",
                                         imageFilename: nil, createdAt: Date(timeIntervalSince1970: 1)))
        _ = try queue.drain()
        #expect(try queue.drain().isEmpty)
    }

    @Test func drainOrdersByCreatedAt() throws {
        let queue = tempQueue()
        try queue.enqueue(PendingCapture(rawType: .text, urlString: nil, text: "second",
                                         imageFilename: nil, createdAt: Date(timeIntervalSince1970: 200)))
        try queue.enqueue(PendingCapture(rawType: .text, urlString: nil, text: "first",
                                         imageFilename: nil, createdAt: Date(timeIntervalSince1970: 100)))
        let drained = try queue.drain()
        #expect(drained.map(\.text) == ["first", "second"])
    }

    @Test func drainEmptyDirectoryReturnsEmpty() throws {
        #expect(try tempQueue().drain().isEmpty)
    }
}
