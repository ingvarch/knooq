import Foundation

/// Drives an item through the pipeline: pending -> extract -> analyze -> processed.
/// Any failure parks the item in .failed so it is retried on the next launch.
/// Pure orchestration over injected protocols (no FM/network/SwiftData knowledge here).
public final class ItemProcessor: Sendable {
    private let analyzer: Analyzer
    private let extractor: TextExtractor
    private let minTextLength: Int
    private let maxTextLength: Int

    public init(
        analyzer: Analyzer,
        extractor: TextExtractor,
        minTextLength: Int = 20,
        maxTextLength: Int = 4000
    ) {
        self.analyzer = analyzer
        self.extractor = extractor
        self.minTextLength = minTextLength
        self.maxTextLength = maxTextLength
    }

    @MainActor
    public func process(_ item: SavedItem) async {
        guard item.status == .pending else { return }
        knooqLog("ItemProcessor: processing \(item.rawType.rawValue) item \(item.id)")

        let text: String
        do {
            text = try await extractor.extract(from: RawPayload(item))
        } catch {
            return fail(item, "Couldn't read content: \(Self.message(error))")
        }
        knooqLog("ItemProcessor: extracted \(text.count) chars")

        guard text.count >= minTextLength else {
            return fail(item, "Too little text to analyze (\(text.count) chars)")
        }

        do {
            let analysis = try await analyzer.analyze(String(text.prefix(maxTextLength)))
            if !item.userCategorized { item.category = analysis.category }
            item.tags = analysis.tags
            if !item.userTitled { item.title = analysis.title }
            // FM writes its own summary; the user's note (item.note) is never touched.
            item.summary = analysis.summary
            item.status = .processed
            item.failureReason = nil
            knooqLog("ItemProcessor: processed -> \(item.category ?? "?") \(item.tags)")
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
