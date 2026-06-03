import SwiftUI
import LinkPresentation

/// Rich link preview via LinkPresentation. Shared by the Share Extension and the app detail view.
struct LinkPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LPLinkView {
        let view = LPLinkView(url: url)
        // Fetch on the main actor via the async API so the non-Sendable metadata never crosses
        // an actor boundary (avoids the @Sendable-completion data-race warnings).
        Task { @MainActor in
            if let metadata = try? await LPMetadataProvider().startFetchingMetadata(for: url) {
                view.metadata = metadata
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
