import Testing
import Foundation
@testable import Knooq
@testable import KnooqKit

@Suite struct CompositeTextExtractorTests {

    @Test func textPayloadReturnsRawText() async throws {
        let extractor = CompositeTextExtractor()
        let payload = RawPayload(rawType: .text, rawURL: nil, rawText: "hello", imageFilename: nil)
        #expect(try await extractor.extract(from: payload) == "hello")
    }

    @Test func urlPayloadWithoutURLThrows() async {
        let extractor = CompositeTextExtractor()
        let payload = RawPayload(rawType: .url, rawURL: nil, rawText: nil, imageFilename: nil)
        await #expect(throws: ExtractionError.missingURL) {
            _ = try await extractor.extract(from: payload)
        }
    }

    @Test func imagePayloadWithoutFilenameThrows() async {
        let extractor = CompositeTextExtractor()
        let payload = RawPayload(rawType: .image, rawURL: nil, rawText: nil, imageFilename: nil)
        await #expect(throws: ExtractionError.missingImage) {
            _ = try await extractor.extract(from: payload)
        }
    }
}
