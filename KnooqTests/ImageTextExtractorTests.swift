import Testing
import Foundation
import UIKit
@testable import Knooq
@testable import KnooqKit

@MainActor
@Suite struct ImageTextExtractorTests {

    private func tempStore() -> ImageStore {
        ImageStore(directory: FileManager.default.temporaryDirectory
            .appendingPathComponent("ocr-\(UUID().uuidString)"))
    }

    private func renderImage(text: String, size: CGFloat = 600) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: size, height: size / 3)
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(bounds)
            guard !text.isEmpty else { return }
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 80),
                .foregroundColor: UIColor.black,
            ]
            (text as NSString).draw(at: CGPoint(x: 20, y: 50), withAttributes: attrs)
        }
        return image.pngData()!
    }

    @Test func extractsRenderedText() async throws {
        let store = tempStore()
        let filename = try store.save(renderImage(text: "KNOOQ"))
        let extractor = ImageTextExtractor(store: store)
        let text = try await extractor.extract(from: filename)
        #expect(text.uppercased().contains("KNOOQ"))
    }

    @Test func throwsOnMissingFile() async {
        let extractor = ImageTextExtractor(store: tempStore())
        await #expect(throws: OCRError.imageLoadFailed) {
            _ = try await extractor.extract(from: "nope.jpg")
        }
    }

    @Test func blankImageReturnsEmpty() async throws {
        let store = tempStore()
        let filename = try store.save(renderImage(text: ""))
        let extractor = ImageTextExtractor(store: store)
        let text = try await extractor.extract(from: filename)
        #expect(text.isEmpty)
    }
}
