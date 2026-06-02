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
        do {
            let text = try await extractor.extract(from: RawPayload(item))
            guard text.count >= minTextLength else {
                item.status = .failed
                return
            }
            let analysis = try await analyzer.analyze(String(text.prefix(maxTextLength)))
            item.category = analysis.category
            item.tags = analysis.tags
            item.title = analysis.title
            item.summary = analysis.summary
            item.status = .processed
        } catch {
            item.status = .failed
        }
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
