import Testing
import Foundation
@testable import KnooqKit

@MainActor
@Suite struct ItemProcessorTests {

    private func makeProcessor(
        extractedText: String = String(repeating: "x", count: 50),
        extractorError: Error? = nil,
        analysis: ItemAnalysis = ItemAnalysis(category: "Article", tags: ["t"], title: "Title", summary: "Sum"),
        analyzerError: Error? = nil
    ) -> (ItemProcessor, StubTextExtractor, StubAnalyzer) {
        let extractor = StubTextExtractor()
        extractor.text = extractedText
        extractor.error = extractorError
        let analyzer = StubAnalyzer()
        analyzer.result = analysis
        analyzer.error = analyzerError
        return (ItemProcessor(analyzer: analyzer, extractor: extractor), extractor, analyzer)
    }

    @Test func processedOnValidTextAndAnalysis() async {
        let (proc, _, _) = makeProcessor()
        let item = SavedItem(rawType: .text, rawText: "raw")
        await proc.process(item)
        #expect(item.status == .processed)
        #expect(item.category == "Article")
        #expect(item.tags == ["t"])
        #expect(item.title == "Title")
        #expect(item.summary == "Sum")
    }

    @Test func failedWhenTextTooShort() async {
        let (proc, _, _) = makeProcessor(extractedText: "short")  // < 20
        let item = SavedItem(rawType: .text)
        await proc.process(item)
        #expect(item.status == .failed)
        #expect(item.category == nil)
    }

    @Test func failedWhenExtractorThrows() async {
        struct Boom: Error {}
        let (proc, _, _) = makeProcessor(extractorError: Boom())
        let item = SavedItem(rawType: .url, rawURL: URL(string: "https://e.com"))
        await proc.process(item)
        #expect(item.status == .failed)
    }

    @Test func failedWhenAnalyzerThrows() async {
        struct Boom: Error {}
        let (proc, _, _) = makeProcessor(analyzerError: Boom())
        let item = SavedItem(rawType: .text)
        await proc.process(item)
        #expect(item.status == .failed)
    }

    @Test func nonPendingItemIsNoOp() async {
        let (proc, _, _) = makeProcessor()
        let item = SavedItem(rawType: .text)
        item.status = .processed
        item.title = "kept"
        await proc.process(item)
        #expect(item.status == .processed)
        #expect(item.title == "kept")  // untouched
    }

    @Test func truncatesToMaxLength() async {
        let (proc, _, analyzer) = makeProcessor(extractedText: String(repeating: "a", count: 5000))
        let item = SavedItem(rawType: .text)
        await proc.process(item)
        #expect(analyzer.receivedText?.count == 4000)
    }

    @Test func retryFailedReprocesses() async {
        let (proc, _, _) = makeProcessor()
        let item = SavedItem(rawType: .text)
        item.status = .failed
        await proc.retryFailed([item])
        #expect(item.status == .processed)
    }
}
