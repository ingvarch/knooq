import Social
import UniformTypeIdentifiers
import KnooqKit

/// Native share card. Raw capture only: enqueue the payload to the App Group file queue and close.
/// No SwiftData, CloudKit, network, or OCR here — that heavy work runs in the main app.
final class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool { true }

    override func configurationItems() -> [Any]! { [] }

    override func didSelectPost() {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .compactMap(\.attachments).flatMap { $0 } ?? []

        Task {
            let queue = CaptureQueue.appGroup()
            for provider in providers {
                if let capture = try? await makeCapture(from: provider) {
                    try? queue.enqueue(capture)
                }
            }
            extensionContext?.completeRequest(returningItems: nil)
        }
    }

    /// First matching type wins: URL, then image, then plain text.
    private func makeCapture(from provider: NSItemProvider) async throws -> PendingCapture? {
        let now = Date()

        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let url = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
            return PendingCapture(rawType: .url, urlString: url.absoluteString, text: nil, imageFilename: nil, createdAt: now)
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            let data = try await loadData(provider, UTType.image.identifier)
            let filename = try ImageStore.appGroup().save(data)
            return PendingCapture(rawType: .image, urlString: nil, text: nil, imageFilename: filename, createdAt: now)
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
           let text = try await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
            return PendingCapture(rawType: .text, urlString: nil, text: text, imageFilename: nil, createdAt: now)
        }

        return nil
    }

    private func loadData(_ provider: NSItemProvider, _ typeIdentifier: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data ?? Data())
                }
            }
        }
    }
}
