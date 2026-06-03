import NaturalLanguage

/// On-device language detection (no UI, no network).
public enum LanguageDetector {
    /// Dominant language as a BCP-47 base code (e.g. "en", "ru"), or nil if undetermined.
    /// `constrainedTo` biases detection to a known set — critical for close scripts
    /// (e.g. Russian vs Bulgarian, both Cyrillic) so we pick the language the user actually uses.
    public static func dominantLanguageCode(_ text: String, constrainedTo languages: [String] = []) -> String? {
        let recognizer = NLLanguageRecognizer()
        if !languages.isEmpty {
            recognizer.languageConstraints = languages.map { NLLanguage($0) }
        }
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }
}
