import Foundation
import Translation
import KnooqKit

/// Bridges the headless pipeline to Apple's SwiftUI-only Translation framework.
/// `translate` publishes a `Configuration`; a `.translationTask` hosted in the view tree picks it
/// up, gets a `TranslationSession`, calls `perform`, and the continuation resumes. Serialized:
/// the pipeline translates one request at a time.
@MainActor
@Observable
final class TranslationBridge: TextTranslator {
    private(set) var config: TranslationSession.Configuration?
    private var pending: (texts: [String], continuation: CheckedContinuation<[String], Error>)?

    func translate(_ texts: [String], from: String?, to: String) async throws -> [String] {
        knooqLog("TranslationBridge: request \(texts.count) text(s) \(from ?? "auto")->\(to)")
        return try await withCheckedThrowingContinuation { continuation in
            pending = (texts, continuation)
            config = TranslationSession.Configuration(
                source: from.map { Locale.Language(identifier: $0) },
                target: Locale.Language(identifier: to)
            )
        }
    }

    /// Runs the queued translation on the session vended by the view's `.translationTask`.
    func perform(_ session: TranslationSession) async {
        guard let request = pending else { return }
        pending = nil
        do {
            var output: [String] = []
            for text in request.texts {
                output.append(try await session.translate(text).targetText)
            }
            knooqLog("TranslationBridge: translated \(output.count) text(s)")
            config = nil
            request.continuation.resume(returning: output)
        } catch {
            knooqLog("TranslationBridge: translation error \(error)")
            config = nil
            request.continuation.resume(throwing: error)
        }
    }
}
