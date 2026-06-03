import Foundation
import UniformTypeIdentifiers
import KnooqKit

/// Shared no-UI capture: turns NSExtension input into PendingCaptures (category = Auto).
/// Used by the quick Action Extension. Mirrors the Share Extension's type routing.
@MainActor
enum CaptureIngest {
    static func captures(from items: [NSExtensionItem]) async -> [PendingCapture] {
        let providers = items.compactMap(\.attachments).flatMap { $0 }
        var result: [PendingCapture] = []
        for provider in providers {
            if let capture = await makeCapture(from: provider) { result.append(capture) }
        }
        return result
    }

    private static func makeCapture(from provider: NSItemProvider) async -> PendingCapture? {
        let now = Date()

        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier),
           let data = try? await loadData(provider, UTType.pdf.identifier) {
            let filename = try? ImageStore.appGroup().save(data, ext: "pdf")
            return PendingCapture(rawType: .pdf, urlString: nil, text: nil, imageFilename: filename, createdAt: now)
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
           let data = try? await loadData(provider, UTType.image.identifier) {
            let filename = try? ImageStore.appGroup().save(data)
            return PendingCapture(rawType: .image, urlString: nil, text: nil, imageFilename: filename, createdAt: now)
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL, !url.isFileURL {
            return PendingCapture(rawType: .url, urlString: url.absoluteString, text: nil, imageFilename: nil, createdAt: now)
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
           let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
            return PendingCapture(rawType: .text, urlString: nil, text: text, imageFilename: nil, createdAt: now)
        }
        return nil
    }

    private static func loadData(_ provider: NSItemProvider, _ typeIdentifier: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: data ?? Data()) }
            }
        }
    }
}
