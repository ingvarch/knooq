import Testing
@testable import KnooqKit

@Suite struct TranslatingAnalyzerTests {

    private func base() -> StubAnalyzer {
        let a = StubAnalyzer()
        a.result = ItemAnalysis(category: .article, tags: ["tag"], title: "Title", summary: "Summary")
        return a
    }

    @Test func passesThroughWhenLanguageNotTranslatable() async throws {
        let translator = StubTranslator()
        let analyzer = TranslatingAnalyzer(
            base: base(), translator: translator,
            translatableLanguages: ["ru"],
            detect: { _ in "en" }
        )
        let out = try await analyzer.analyze("hello")
        #expect(out.title == "Title")
        #expect(translator.calls.isEmpty)  // no translation
    }

    @Test func translatesInThenOutForTranslatableLanguage() async throws {
        let translator = StubTranslator()
        let analyzer = TranslatingAnalyzer(
            base: base(), translator: translator,
            translatableLanguages: ["ru"],
            detect: { _ in "ru" }
        )
        let out = try await analyzer.analyze("привет")

        // in: ru -> en, out: en -> ru
        #expect(translator.calls.count == 2)
        #expect(translator.calls[0].to == "en")
        #expect(translator.calls[0].from == "ru")
        #expect(translator.calls[1].to == "ru")
        // back-translated fields are marked "ru:"
        #expect(out.title == "ru:Title")
        #expect(out.summary == "ru:Summary")
        #expect(out.tags == ["ru:tag"])
        #expect(out.category == .article)  // category never translated
    }

    @Test func fallsBackToBaseWhenTranslationThrows() async throws {
        struct Boom: Error {}
        let translator = StubTranslator()
        translator.error = Boom()
        let analyzer = TranslatingAnalyzer(
            base: base(), translator: translator,
            translatableLanguages: ["ru"],
            detect: { _ in "ru" }
        )
        let out = try await analyzer.analyze("привет")
        #expect(out.title == "Title")  // base result, untranslated
    }

    @Test func detectorIdentifiesLanguages() {
        #expect(LanguageDetector.dominantLanguageCode("This is clearly an English sentence.") == "en")
        #expect(LanguageDetector.dominantLanguageCode("Это явно русское предложение.") == "ru")
    }

    @Test func constraintsResolveCyrillicToUserLanguage() {
        // Without constraints Cyrillic can resolve to Bulgarian; constrained to the user's set it must be Russian.
        let text = "Сегодня хорошая погода и мы пойдём гулять в парк с друзьями."
        #expect(LanguageDetector.dominantLanguageCode(text, constrainedTo: ["ru", "en"]) == "ru")
    }
}
