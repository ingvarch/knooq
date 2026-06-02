import Foundation

/// Pure category/tag filtering, shared by the Inbox and Categories screens (DRY).
@MainActor
public enum ItemFilter {
    public static func apply(_ items: [SavedItem], category: ItemCategory?, tag: String?) -> [SavedItem] {
        items.filter { item in
            if let category, item.category != category { return false }
            if let tag, !item.tags.contains(tag) { return false }
            return true
        }
    }

    public static func allTags(_ items: [SavedItem]) -> [String] {
        Array(Set(items.flatMap(\.tags))).sorted()
    }
}
