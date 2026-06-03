import Vision
import UIKit
import KnooqKit

enum OCRError: Error {
    case imageLoadFailed
}

/// On-device OCR via Vision. Reads the image from the shared `ImageStore` (DRY/DIP) and
/// returns recognized text. Main app only.
final class ImageTextExtractor: Sendable {
    private let store: ImageStore

    init(store: ImageStore = .appGroup()) {
        self.store = store
    }

    func extract(from filename: String) async throws -> String {
        guard let data = try? store.data(for: filename),
              let cgImage = UIImage(data: data)?.cgImage else {
            throw OCRError.imageLoadFailed
        }
        return try await recognizeText(in: cgImage)
    }
}
