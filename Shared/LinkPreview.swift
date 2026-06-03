import SwiftUI
import LinkPresentation

/// Rich link preview via LinkPresentation. Shared by the Share Extension and the app detail view.
struct LinkPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LPLinkView {
        // Use cached metadata if we have it — no network, instant.
        if let cached = LinkMetadataCache.shared.metadata(for: url) {
            return LPLinkView(metadata: cached)
        }
        let view = LPLinkView(url: url)
        // Fetch once, render, and cache for next time. Async on the main actor so the
        // non-Sendable metadata never crosses an actor boundary.
        Task { @MainActor in
            if let metadata = try? await LPMetadataProvider().startFetchingMetadata(for: url) {
                view.metadata = metadata
                LinkMetadataCache.shared.store(metadata, for: url)
            }
        }
        return view
    }

    func updateUIView(_ uiView: LPLinkView, context: Context) {}

    /// Pin a definite height so LPLinkView doesn't grab its full intrinsic size and overlap siblings.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: LPLinkView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 320, height: 160)
    }
}
