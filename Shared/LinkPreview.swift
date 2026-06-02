import SwiftUI
@preconcurrency import LinkPresentation

/// Rich link preview via LinkPresentation. Shared by the Share Extension and the app detail view.
struct LinkPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LPLinkView {
        let view = LPLinkView(url: url)
        LPMetadataProvider().startFetchingMetadata(for: url) { metadata, _ in
            guard let metadata else { return }
            DispatchQueue.main.async { view.metadata = metadata }
        }
        return view
    }

    func updateUIView(_ uiView: LPLinkView, context: Context) {}
}
