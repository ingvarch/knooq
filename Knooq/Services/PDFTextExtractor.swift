import PDFKit
import UIKit
import KnooqKit

enum PDFError: Error {
    case loadFailed
}

/// Extracts text from a shared PDF. Uses the PDF's embedded text when present; otherwise renders
/// each page and runs Vision OCR (scanned PDFs). Reads the file from the shared `ImageStore`.
final class PDFTextExtractor: Sendable {
    private let store: ImageStore
    private let maxOCRPages: Int

    init(store: ImageStore = .appGroup(), maxOCRPages: Int = 30) {
        self.store = store
        self.maxOCRPages = maxOCRPages
    }

    func extract(from filename: String) async throws -> String {
        guard let document = PDFDocument(url: store.url(for: filename)) else {
            throw PDFError.loadFailed
        }

        // 1. Embedded text (text-based PDFs).
        if let text = document.string, text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20 {
            knooqLog("PDFTextExtractor: embedded text \(text.count) chars")
            return text
        }

        // 2. Fallback: render pages and OCR (scanned PDFs).
        knooqLog("PDFTextExtractor: no embedded text, OCR up to \(maxOCRPages) pages")
        var pieces: [String] = []
        for index in 0..<min(document.pageCount, maxOCRPages) {
            guard let page = document.page(at: index), let cgImage = render(page) else { continue }
            pieces.append(try await recognizeText(in: cgImage))
        }
        return pieces.joined(separator: "\n")
    }

    private func render(_ page: PDFPage) -> CGImage? {
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: bounds.size))
            context.cgContext.translateBy(x: 0, y: bounds.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        return image.cgImage
    }
}
