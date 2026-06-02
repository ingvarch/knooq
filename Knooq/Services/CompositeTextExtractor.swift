import KnooqKit

enum ExtractionError: Error {
    case missingURL
    case missingImage
}

/// Routes extraction by raw type: text as-is, URL via Readability, image via Vision OCR.
/// The single `TextExtractor` the pipeline depends on (composition over branching in the processor).
final class CompositeTextExtractor: TextExtractor {
    private let imageExtractor: ImageTextExtractor

    init(imageExtractor: ImageTextExtractor = ImageTextExtractor()) {
        self.imageExtractor = imageExtractor
    }

    func extract(from payload: RawPayload) async throws -> String {
        switch payload.rawType {
        case .text:
            return payload.rawText ?? ""
        case .url:
            guard let url = payload.rawURL else { throw ExtractionError.missingURL }
            // Fresh extractor per call: URLTextExtractor holds per-load WebView state and is
            // NOT safe to share across concurrent extractions.
            return try await URLTextExtractor().extract(from: url)
        case .image:
            guard let filename = payload.imageFilename else { throw ExtractionError.missingImage }
            return try await imageExtractor.extract(from: filename)
        }
    }
}
