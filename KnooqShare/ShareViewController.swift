import UIKit
import UniformTypeIdentifiers
import KnooqKit

/// Frictionless capture: no title prompt. Enqueue the payload to the App Group queue,
/// show a brief confirmation, close. No SwiftData/CloudKit/network/OCR here.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupConfirmation()
        Task {
            await saveAll()
            try? await Task.sleep(for: .milliseconds(650))
            extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func saveAll() async {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .compactMap(\.attachments).flatMap { $0 } ?? []
        let queue = CaptureQueue.appGroup()
        for provider in providers {
            if let capture = try? await makeCapture(from: provider) {
                try? queue.enqueue(capture)
            }
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
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: data ?? Data()) }
            }
        }
    }

    private func setupConfirmation() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)

        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false

        let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        check.tintColor = .systemGreen
        check.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = "Saved to Knooq"
        label.font = .preferredFont(forTextStyle: .headline)

        let stack = UIStackView(arrangedSubviews: [check, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        view.addSubview(card)

        NSLayoutConstraint.activate([
            check.heightAnchor.constraint(equalToConstant: 44),
            check.widthAnchor.constraint(equalToConstant: 44),
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 36),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -36),
        ])
    }
}
