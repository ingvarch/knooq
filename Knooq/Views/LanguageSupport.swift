import SwiftUI
import Translation

/// Languages offered for on-device translation (English is the AI's working language).
enum LanguageCatalog {
    static let offered = ["ru", "uk", "es", "fr", "de", "it", "pt-BR", "ja", "ko", "zh-Hans", "ar", "hi", "tr", "pl"]
    static let english = Locale.Language(identifier: "en")

    static func displayName(_ code: String) -> String {
        Locale.current.localizedString(forIdentifier: code)
            ?? Locale.current.localizedString(forLanguageCode: code)
            ?? code
    }

    /// lang↔English configs for the given codes (both directions, for translate-in and back-out).
    static func configurations(for codes: [String]) -> [TranslationSession.Configuration] {
        codes.flatMap { code -> [TranslationSession.Configuration] in
            let lang = Locale.Language(identifier: code)
            return [
                TranslationSession.Configuration(source: lang, target: english),
                TranslationSession.Configuration(source: english, target: lang),
            ]
        }
    }

    /// Whether each code's pack is downloaded.
    static func installedStatus(for codes: [String]) async -> [String: Bool] {
        let availability = LanguageAvailability()
        var result: [String: Bool] = [:]
        for code in codes {
            let status = await availability.status(from: Locale.Language(identifier: code), to: english)
            result[code] = (status == .installed)
        }
        return result
    }
}

/// Drives sequential download of translation packs. A @MainActor @Observable class (so it is
/// Sendable) — the translationTask closure calls `prepared()` without sending non-Sendable state.
@MainActor
@Observable
final class PackDownloader {
    private(set) var activeConfig: TranslationSession.Configuration?
    private(set) var isWorking = false
    private var queue: [TranslationSession.Configuration] = []
    private var onFinish: () -> Void = {}

    func start(_ configs: [TranslationSession.Configuration], onFinish: @escaping () -> Void) {
        guard !configs.isEmpty else { onFinish(); return }
        queue = configs
        self.onFinish = onFinish
        isWorking = true
        activeConfig = queue.first
    }

    func prepared() {
        if !queue.isEmpty { queue.removeFirst() }
        if let next = queue.first {
            activeConfig = next
        } else {
            isWorking = false
            activeConfig = nil
            onFinish()
        }
    }
}

/// Multi-select list of offered languages, with optional download status badges.
struct LanguagePicker: View {
    @Binding var selected: Set<String>
    var installed: [String: Bool] = [:]

    var body: some View {
        ForEach(LanguageCatalog.offered, id: \.self) { code in
            Button {
                if selected.contains(code) { selected.remove(code) } else { selected.insert(code) }
            } label: {
                HStack {
                    Text(LanguageCatalog.displayName(code)).foregroundStyle(.primary)
                    Spacer()
                    if let isInstalled = installed[code] {
                        Text(isInstalled ? "Downloaded" : "Not downloaded")
                            .font(.caption)
                            .foregroundStyle(isInstalled ? .green : .secondary)
                    }
                    if selected.contains(code) {
                        Image(systemName: "checkmark").foregroundStyle(.tint)
                    }
                }
            }
        }
    }
}
