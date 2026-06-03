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

        // Describe the image (what's in it) + any text on it, so FM can summarize a photo
        // even when it contains no text. Labels are English, keeping FM input on a supported locale.
        let labels = await classifyImage(cgImage)
        let text = try await recognizeText(in: cgImage)

        var parts: [String] = []
        if !labels.isEmpty { parts.append("This image appears to show: \(labels.joined(separator: ", ")).") }
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty { parts.append("Text visible in the image:\n\(trimmedText)") }
        if parts.isEmpty { parts.append("A photo with no clearly recognizable objects or text.") }

        let description = parts.joined(separator: "\n")
        knooqLog("ImageTextExtractor: labels=\(labels) textChars=\(trimmedText.count)")
        return description
    }
}
