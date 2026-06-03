import Foundation

/// Drives an item through the pipeline: pending -> extract -> analyze -> processed.
/// Any failure parks the item in .failed so it is retried on the next launch.
/// Pure orchestration over injected protocols (no FM/network/SwiftData knowledge here).
public final class ItemProcessor: Sendable {
    private enum PipelineError: Error {
        case tooShort(Int)
        case extract(Error)
        case analyze(Error)
    }

    private let analyzer: Analyzer
    private let extractor: TextExtractor
    private let minTextLength: Int
    private let maxTextLength: Int
    private let timeoutSeconds: Double

    public init(
        analyzer: Analyzer,
        extractor: TextExtractor,
        minTextLength: Int = 20,
        maxTextLength: Int = 4000,
        timeoutSeconds: Double = 90
    ) {
        self.analyzer = analyzer
        self.extractor = extractor
        self.minTextLength = minTextLength
        self.maxTextLength = maxTextLength
        self.timeoutSeconds = timeoutSeconds
    }

    @MainActor
    public func process(_ item: SavedItem) async {
        guard item.status == .pending else { return }
        knooqLog("ItemProcessor: processing \(item.rawType.rawValue) item \(item.id)")

        // Run extract + analyze under a single timeout so one slow/hung item can't sit in
        // Processing forever (and block the rest of the queue). Item mutation stays on the
        // main actor; only Sendable values cross into the timed operation.
        let payload = RawPayload(item)
        let extractor = self.extractor
        let analyzer = self.analyzer
        let minLength = minTextLength
        let maxLength = maxTextLength

        do {
            let analysis = try await withTimeout(seconds: timeoutSeconds) { () -> ItemAnalysis in
                let text: String
                do { text = try await extractor.extract(from: payload) }
                catch { throw PipelineError.extract(error) }
                guard text.count >= minLength else { throw PipelineError.tooShort(text.count) }
                do { return try await analyzer.analyze(String(text.prefix(maxLength))) }
                catch { throw PipelineError.analyze(error) }
            }

            if !item.userCategorized { item.category = analysis.category }
            let source = SourceTag.for(rawType: item.rawType, rawURL: item.rawURL)
            item.tags = SourceTag.compose(source: source, fmTags: analysis.tags, max: 3)
            if !item.userTitled { item.title = analysis.title }
            // FM writes its own summary; the user's note (item.note) is never touched.
            item.summary = analysis.summary
            item.status = .processed
            item.failureReason = nil
            knooqLog("ItemProcessor: processed -> \(item.category ?? "?") \(item.tags)")
        } catch is TimeoutError {
            knooqLog("ItemProcessor: timed out after \(Int(timeoutSeconds))s on item \(item.id)")
            fail(item, "Couldn't finish processing in time. Pull down to refresh and retry.")
        } catch PipelineError.tooShort(let count) {
            fail(item, "Too little text to analyze (\(count) chars)")
        } catch PipelineError.extract(let error) {
            fail(item, "Couldn't read content: \(Self.message(error))")
        } catch PipelineError.analyze(let error) {
            fail(item, Self.message(error))
        } catch {
            fail(item, Self.message(error))
        }
    }

    @MainActor
    private func fail(_ item: SavedItem, _ reason: String) {
        item.status = .failed
        item.failureReason = reason
    }

    private static func message(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    @MainActor
    public func processAll(_ items: [SavedItem]) async {
        for item in items where item.status == .pending {
            await process(item)
        }
    }

    @MainActor
    public func retryFailed(_ items: [SavedItem]) async {
        for item in items where item.status == .failed {
            item.status = .pending
            await process(item)
        }
    }
}
