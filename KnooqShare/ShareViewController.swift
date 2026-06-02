import UIKit
import UniformTypeIdentifiers
import SwiftData
import KnooqKit

/// Raw capture only: read the shared payload, persist it as `.pending`, close.
/// No AI, no network, no OCR here — that work runs in the main app (extension memory budget).
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        Task { await handleShare() }
    }

    @MainActor
    private func handleShare() async {
        defer { extensionContext?.completeRequest(returningItems: nil) }

        let attachments = (extensionContext?.inputItems as? [NSExtensionItem])?
            .compactMap(\.attachments).flatMap { $0 } ?? []
        guard !attachments.isEmpty else { return }

        do {
            let context = try KnooqStore.container().mainContext
            for provider in attachments {
                if let item = try await makeItem(from: provider) {
                    context.insert(item)
                }
            }
            try context.save()
        } catch {
            // Nothing to surface in the extension; the item simply isn't captured.
        }
    }

    /// First matching type wins: URL, then image, then plain text.
    private func makeItem(from provider: NSItemProvider) async throws -> SavedItem? {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let url = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
            return SavedItem(rawType: .url, rawURL: url)
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            let data = try await loadData(provider, UTType.image.identifier)
            let filename = try ImageStore.appGroup().save(data)
            return SavedItem(rawType: .image, imageFilename: filename)
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
           let text = try await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
            return SavedItem(rawType: .text, rawText: text)
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
