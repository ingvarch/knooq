import SwiftUI
import KnooqKit

/// Settings modal: view and manage the translation languages the user picked and downloaded.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var store = OnboardingStore()
    @State private var selected: Set<String> = []
    @State private var installed: [String: Bool] = [:]
    @State private var downloader = PackDownloader()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LanguagePicker(selected: $selected, installed: installed)
                } header: {
                    Text("Translation languages")
                } footer: {
                    Text("Languages you save content in. Knooq translates them to and from English on device so Apple Intelligence can organize them.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if downloader.isWorking {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                    }
                }
            }
            .translationTask(downloader.activeConfig) { session in
                try? await session.prepareTranslation()
                downloader.prepared()
            }
            .task {
                selected = Set(store.translationLanguageCodes)
                installed = await LanguageCatalog.installedStatus(for: LanguageCatalog.offered)
            }
        }
    }

    private func save() {
        let codes = LanguageCatalog.offered.filter { selected.contains($0) }
        store.translationLanguageCodes = codes
        // Download any newly selected languages, then refresh status and close.
        downloader.start(LanguageCatalog.configurations(for: codes)) {
            Task {
                installed = await LanguageCatalog.installedStatus(for: LanguageCatalog.offered)
                dismiss()
            }
        }
    }
}
