import KnooqKit

enum ExtractionError: Error {
    case missingURL
    case missingImage
}

/// Routes extraction by raw type: text as-is, URL via Readability, image via Vision OCR.
/// The single `TextExtractor` the pipeline depends on (composition over branching in the processor).
final class CompositeTextExtractor: TextExtractor {
    private let urlExtractor: URLTextExtractor
    private let imageExtractor: ImageTextExtractor

    init(urlExtractor: URLTextExtractor = URLTextExtractor(),
         imageExtractor: ImageTextExtractor = ImageTextExtractor()) {
        self.urlExtractor = urlExtractor
        self.imageExtractor = imageExtractor
    }

    func extract(from payload: RawPayload) async throws -> String {
        switch payload.rawType {
        case .text:
            return payload.rawText ?? ""
        case .url:
            guard let url = payload.rawURL else { throw ExtractionError.missingURL }
            return try await urlExtractor.extract(from: url)
        case .image:
            guard let filename = payload.imageFilename else { throw ExtractionError.missingImage }
            return try await imageExtractor.extract(from: filename)
        }
    }
}
