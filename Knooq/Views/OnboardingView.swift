import SwiftUI

/// First-run onboarding: explains Knooq, lets the user pick the languages they save content in,
/// and downloads the on-device translation packs so the AI can understand them.
struct OnboardingView: View {
    let onComplete: ([String]) -> Void

    @State private var selected: Set<String> = []
    @State private var downloader = PackDownloader()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.tint)
                        Text("Welcome to Knooq")
                            .font(.title2.bold())
                        Text("Save links, images, and notes. On-device AI organizes them and brings them back before you forget.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    LanguagePicker(selected: $selected)
                } header: {
                    Text("Languages you save in")
                } footer: {
                    Text("Apple Intelligence works in a limited set of languages. Knooq translates the languages you pick (to and from English) entirely on device. You can change these later in Settings.")
                }
            }
            .navigationTitle("Set up Knooq")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: start) {
                    Group {
                        if downloader.isWorking { ProgressView() }
                        else { Text(selected.isEmpty ? "Continue" : "Download & Continue") }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(downloader.isWorking)
                .padding()
            }
            .translationTask(downloader.activeConfig) { session in
                try? await session.prepareTranslation()
                downloader.prepared()
            }
        }
    }

    private func start() {
        let codes = LanguageCatalog.offered.filter { selected.contains($0) }
        downloader.start(LanguageCatalog.configurations(for: codes)) { onComplete(codes) }
    }
}
