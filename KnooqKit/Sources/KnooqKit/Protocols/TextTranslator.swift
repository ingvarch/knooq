/// Translates text between languages. Prod: Apple Translation framework (via SwiftUI bridge);
/// test: a stub. `from` is a BCP-47 code (nil = auto-detect), `to` is a BCP-47 code.
public protocol TextTranslator: Sendable {
    func translate(_ texts: [String], from: String?, to: String) async throws -> [String]
}
