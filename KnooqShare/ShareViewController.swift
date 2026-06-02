import Social
import UniformTypeIdentifiers
import KnooqKit

/// Native share card with an optional title field (Post/Cancel). Raw capture only:
/// enqueue the payload (+ typed title) to the App Group queue and close. No SwiftData/CloudKit here.
final class ShareViewController: SLComposeServiceViewController {

    override func presentationAnimationDidFinish() {
        super.presentationAnimationDidFinish()
        placeholder = "Optional title (AI names it if blank)"
    }

    override func isContentValid() -> Bool { true }

    override func configurationItems() -> [Any]! { [] }

    override func didSelectPost() {
        let note = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .compactMap(\.attachments).flatMap { $0 } ?? []

        Task {
            let queue = CaptureQueue.appGroup()
            for provider in providers {
                if let capture = try? await makeCapture(from: provider, note: note.isEmpty ? nil : note) {
                    try? queue.enqueue(capture)
                }
            }
            extensionContext?.completeRequest(returningItems: nil)
        }
    }

    /// First matching type wins: URL, then image, then plain text.
    private func makeCapture(from provider: NSItemProvider, note: String?) async throws -> PendingCapture? {
        let now = Date()
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let url = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
            return PendingCapture(rawType: .url, urlString: url.absoluteString, text: nil, imageFilename: nil, createdAt: now, note: note)
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            let data = try await loadData(provider, UTType.image.identifier)
            let filename = try ImageStore.appGroup().save(data)
            return PendingCapture(rawType: .image, urlString: nil, text: nil, imageFilename: filename, createdAt: now, note: note)
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
           let text = try await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
            return PendingCapture(rawType: .text, urlString: nil, text: text, imageFilename: nil, createdAt: now, note: note)
        }
        return nil
    }

    private func loadData(_ provider: NSItemProvider, _ typeIdentifier: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: data ?? Data()) }
            }
        }
    }
}
