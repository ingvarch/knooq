import Foundation

/// Wraps a base `Analyzer` (FM) with translation for languages Apple Intelligence handles poorly.
/// If the detected language is one the user set up for translation: text -> English -> FM ->
/// translate title/summary/tags back. Otherwise the base analyzer runs directly.
/// On any translation failure it falls back to the base result (graceful).
public final class TranslatingAnalyzer: Analyzer {
    private let base: Analyzer
    private let translator: TextTranslator
    private let translatableLanguages: Set<String>
    private let detect: @Sendable (String) -> String?

    public init(
        base: Analyzer,
        translator: TextTranslator,
        translatableLanguages: Set<String>,
        detect: (@Sendable (String) -> String?)? = nil
    ) {
        self.base = base
        self.translator = translator
        self.translatableLanguages = translatableLanguages
        // Constrain detection to the user's languages + English so close scripts
        // (Russian vs Bulgarian) resolve to the language the user actually saves in.
        let constraints = Array(translatableLanguages) + ["en"]
        self.detect = detect ?? { LanguageDetector.dominantLanguageCode($0, constrainedTo: constraints) }
    }

    public func analyze(_ text: String) async throws -> ItemAnalysis {
        let code = detect(text)
        knooqLog("TranslatingAnalyzer: detected language = \(code ?? "nil")")

        guard let code, translatableLanguages.contains(code) else {
            knooqLog("TranslatingAnalyzer: no translation needed, analyzing directly")
            return try await base.analyze(text)
        }

        do {
            knooqLog("TranslatingAnalyzer: translating \(code) -> en")
            let english = try await translator.translate([text], from: code, to: "en").first ?? text
            let result = try await base.analyze(english)

            knooqLog("TranslatingAnalyzer: translating result en -> \(code)")
            let back = try await translator.translate([result.title, result.summary] + result.tags, from: "en", to: code)
            guard back.count >= 2 else { return result }

            return ItemAnalysis(
                category: result.category,
                tags: Array(back.dropFirst(2)),
                title: back[0],
                summary: back[1]
            )
        } catch {
            knooqLog("TranslatingAnalyzer: translation failed (\(error)); falling back to direct analysis")
            return try await base.analyze(text)
        }
    }
}
