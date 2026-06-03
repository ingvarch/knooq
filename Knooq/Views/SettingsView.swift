import SwiftUI
import KnooqKit

/// Settings menu modal. Sub-pages (like Languages) push onto the stack.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = OnboardingStore()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        RemindersView()
                    } label: {
                        Label("Reminders", systemImage: "bell")
                    }
                }

                Section("Translation") {
                    NavigationLink {
                        LanguagesView()
                    } label: {
                        HStack {
                            Label("Languages", systemImage: "globe")
                            Spacer()
                            Text("\(store.translationLanguageCodes.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

/// Manage the translation languages the user picked and downloaded.
struct LanguagesView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var store = OnboardingStore()
    @State private var selected: Set<String> = []
    @State private var installed: [String: Bool] = [:]
    @State private var downloader = PackDownloader()

    var body: some View {
        List {
            Section {
                LanguagePicker(selected: $selected, installed: installed)
            } footer: {
                Text("Languages you save content in. Knooq translates them to and from English on device so Apple Intelligence can organize them.")
            }
        }
        .navigationTitle("Languages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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

    private func save() {
        let codes = LanguageCatalog.offered.filter { selected.contains($0) }
        store.translationLanguageCodes = codes
        downloader.start(LanguageCatalog.configurations(for: codes)) {
            Task {
                installed = await LanguageCatalog.installedStatus(for: LanguageCatalog.offered)
                dismiss()
            }
        }
    }
}
