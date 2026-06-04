import Foundation
import Translation
import UIKit
import KnooqKit

/// Bridges the headless pipeline to Apple's SwiftUI-only Translation framework.
/// `translate` publishes a `Configuration`; a `.translationTask` hosted in the view tree picks it
/// up, gets a `TranslationSession`, calls `perform`, and the continuation resumes. Serialized:
/// the pipeline translates one request at a time.
@MainActor
@Observable
final class TranslationBridge: TextTranslator {
    /// No foreground view can host a session (e.g. background refresh). Caller falls back.
    struct HostUnavailable: Error {}

    private(set) var config: TranslationSession.Configuration?
    private var pending: (texts: [String], continuation: CheckedContinuation<[String], Error>)?

    func translate(_ texts: [String], from: String?, to: String) async throws -> [String] {
        // Sessions are vended by a SwiftUI `.translationTask`; in the background there is no
        // view to host one, so fail fast instead of hanging until the pipeline timeout.
        guard UIApplication.shared.applicationState != .background else {
            knooqLog("TranslationBridge: app backgrounded, no session host")
            throw HostUnavailable()
        }
        knooqLog("TranslationBridge: request \(texts.count) text(s) \(from ?? "auto")->\(to)")
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending = (texts, continuation)
                config = TranslationSession.Configuration(
                    source: from.map { Locale.Language(identifier: $0) },
                    target: Locale.Language(identifier: to)
                )
            }
        } onCancel: {
            // Pipeline timeout cancels the task; resume so the continuation never leaks.
            Task { @MainActor in self.cancelPending(CancellationError()) }
        }
    }

    /// Runs the queued translation on the session vended by the view's `.translationTask`.
    func perform(_ session: TranslationSession) async {
        guard let request = pending else { return }
        pending = nil
        do {
            // Download the language pack if it isn't installed (no-op if it is). Keeps `config`
            // non-nil for the whole download so the system's progress sheet isn't dismissed
            // mid-flight — the first translation succeeds without needing an app restart.
            try await session.prepareTranslation()
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

    /// Resume and clear a waiting request without a result (cancellation). First caller wins.
    private func cancelPending(_ error: Error) {
        guard let request = pending else { return }
        pending = nil
        config = nil
        request.continuation.resume(throwing: error)
    }
}
