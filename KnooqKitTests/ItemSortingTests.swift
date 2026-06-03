import Testing
import Foundation
@testable import KnooqKit

@MainActor
@Suite struct ItemSortingTests {

    private func item(title: String, created: TimeInterval, edited: TimeInterval?) -> SavedItem {
        let item = SavedItem(createdAt: Date(timeIntervalSince1970: created), rawType: .text)
        item.title = title
        if let edited { item.openedAt = Date(timeIntervalSince1970: edited) }
        return item
    }

    @Test func dateCreatedNewestFirst() {
        let a = item(title: "A", created: 100, edited: nil)
        let b = item(title: "B", created: 200, edited: nil)
        let out = ItemSorting.sorted([a, b], by: ItemSort(field: .dateCreated, order: .newestFirst))
        #expect(out.map { $0.title } == ["B", "A"])
    }

    @Test func dateCreatedOldestFirst() {
        let a = item(title: "A", created: 100, edited: nil)
        let b = item(title: "B", created: 200, edited: nil)
        let out = ItemSorting.sorted([a, b], by: ItemSort(field: .dateCreated, order: .oldestFirst))
        #expect(out.map { $0.title } == ["A", "B"])
    }

    @Test func dateEditedUsesOpenedAtFallingBackToCreated() {
        let a = item(title: "A", created: 100, edited: 500)   // edited late
        let b = item(title: "B", created: 300, edited: nil)    // edited = created 300
        let out = ItemSorting.sorted([a, b], by: ItemSort(field: .dateEdited, order: .newestFirst))
        #expect(out.map { $0.title } == ["A", "B"])  // 500 > 300
    }

    @Test func titleAscending() {
        let a = item(title: "Banana", created: 1, edited: nil)
        let b = item(title: "apple", created: 2, edited: nil)
        let out = ItemSorting.sorted([a, b], by: ItemSort(field: .title, order: .oldestFirst))
        #expect(out.map { $0.title } == ["apple", "Banana"])
    }

    @Test func defaultIsDateEditedNewest() {
        let sort = ItemSort()
        #expect(sort.field == .dateEdited)
        #expect(sort.order == .newestFirst)
    }
}
