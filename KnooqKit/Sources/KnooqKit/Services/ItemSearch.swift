import Foundation

/// Pure full-text matching over an item's title, summary, note, and tags (case-insensitive).
@MainActor
public enum ItemSearch {
    public static func matches(_ item: SavedItem, query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return false }
        let fields = [item.title, item.summary, item.note].compactMap { $0 } + item.tags
        return fields.contains { $0.localizedCaseInsensitiveContains(q) }
    }

    public static func search(_ items: [SavedItem], query: String) -> [SavedItem] {
        items.filter { matches($0, query: query) }
    }
}
