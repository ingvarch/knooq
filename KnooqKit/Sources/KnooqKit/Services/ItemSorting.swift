import Foundation

public enum ItemSortField: String, Sendable, CaseIterable, Hashable {
    case dateEdited
    case dateCreated
    case title
}

public enum ItemSortOrder: String, Sendable, CaseIterable, Hashable {
    case newestFirst   // descending: latest date / Z→A
    case oldestFirst   // ascending:  earliest date / A→Z
}

public struct ItemSort: Sendable, Hashable {
    public var field: ItemSortField
    public var order: ItemSortOrder

    public init(field: ItemSortField = .dateEdited, order: ItemSortOrder = .newestFirst) {
        self.field = field
        self.order = order
    }
}

@MainActor
public enum ItemSorting {
    /// "Edited" = when the user last touched the item, falling back to its creation date.
    public static func editedDate(_ item: SavedItem) -> Date {
        item.openedAt ?? item.createdAt
    }

    public static func sorted(_ items: [SavedItem], by sort: ItemSort) -> [SavedItem] {
        let ascending = sort.order == .oldestFirst
        return items.sorted { lhs, rhs in
            switch sort.field {
            case .dateEdited:
                return ascending ? editedDate(lhs) < editedDate(rhs) : editedDate(lhs) > editedDate(rhs)
            case .dateCreated:
                return ascending ? lhs.createdAt < rhs.createdAt : lhs.createdAt > rhs.createdAt
            case .title:
                let l = (lhs.title ?? "").localizedLowercase
                let r = (rhs.title ?? "").localizedLowercase
                return ascending ? l < r : l > r
            }
        }
    }
}
