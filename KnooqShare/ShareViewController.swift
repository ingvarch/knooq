import UIKit
import SwiftUI
import UniformTypeIdentifiers
import KnooqKit

/// What was shared, prepared for the capture UI. Image is already saved to the App Group;
/// `imageData` is kept only for the on-screen preview.
struct SharePayload {
    let rawType: RawType
    let url: URL?
    let text: String?
    let imageFilename: String?
    let imageData: Data?
}

/// Hosts the custom capture screen. Extracts the payload, then shows SwiftUI. Raw capture only:
/// on Save it enqueues to the App Group queue and closes. No SwiftData/CloudKit/network here.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        Task {
            guard let payload = await extractPayload() else { cancel(); return }
            let root = ShareCaptureView(
                payload: payload,
                onCancel: { [weak self] in self?.cancel() },
                onSave: { [weak self] category, note in self?.save(payload, category: category, note: note) }
            )
            embed(UIHostingController(rootView: root))
        }
    }

    private func embed(_ child: UIViewController) {
        addChild(child)
        child.view.frame = view.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "Knooq", code: 0))
    }

    private func save(_ payload: SharePayload, category: String?, note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let capture: PendingCapture

        switch payload.rawType {
        case .text:
            // The editable field IS the text content for text shares.
            capture = PendingCapture(rawType: .text, urlString: nil,
                                     text: trimmed.isEmpty ? payload.text : trimmed,
                                     imageFilename: nil, createdAt: now, note: nil, category: category)
        case .url:
            capture = PendingCapture(rawType: .url, urlString: payload.url?.absoluteString,
                                     text: nil, imageFilename: nil, createdAt: now,
                                     note: trimmed.isEmpty ? nil : trimmed, category: category)
        case .image:
            capture = PendingCapture(rawType: .image, urlString: nil, text: nil,
                                     imageFilename: payload.imageFilename, createdAt: now,
                                     note: trimmed.isEmpty ? nil : trimmed, category: category)
        case .pdf:
            capture = PendingCapture(rawType: .pdf, urlString: nil, text: nil,
                                     imageFilename: payload.imageFilename, createdAt: now,
                                     note: trimmed.isEmpty ? nil : trimmed, category: category)
        }

        try? CaptureQueue.appGroup().enqueue(capture)
        extensionContext?.completeRequest(returningItems: nil)
    }

    // MARK: - Payload extraction

    private func extractPayload() async -> SharePayload? {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .compactMap(\.attachments).flatMap { $0 } ?? []

        for provider in providers {
            // PDF first — a shared PDF can also expose a file URL, so check it before .url.
            if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier),
               let data = try? await loadData(provider, UTType.pdf.identifier) {
                let filename = try? ImageStore.appGroup().save(data, ext: "pdf")
                return SharePayload(rawType: .pdf, url: nil, text: nil, imageFilename: filename, imageData: nil)
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
               let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                return SharePayload(rawType: .url, url: url, text: nil, imageFilename: nil, imageData: nil)
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
               let data = try? await loadData(provider, UTType.image.identifier) {
                let filename = try? ImageStore.appGroup().save(data)
                return SharePayload(rawType: .image, url: nil, text: nil, imageFilename: filename, imageData: data)
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
               let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                return SharePayload(rawType: .text, url: nil, text: text, imageFilename: nil, imageData: nil)
            }
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
