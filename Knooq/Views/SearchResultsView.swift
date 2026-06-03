import SwiftUI
import KnooqKit

/// Search results: a "Top Hits" block, then sections grouped by folder. Rows open the item.
struct SearchResultsView: View {
    let query: String
    let items: [SavedItem]

    private var results: [SavedItem] {
        ItemSearch.search(items.filter { $0.status == .processed }, query: query)
            .sorted { $0.createdAt > $1.createdAt }
    }
    private var topHits: [SavedItem] { Array(results.prefix(2)) }
    private var byFolder: [(name: String, items: [SavedItem])] {
        let groups = Dictionary(grouping: results.dropFirst(2)) { $0.category ?? Categories.other }
        return groups.map { (name: $0.key, items: $0.value) }.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            if results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                if !topHits.isEmpty {
                    Section("Top Hits") { rows(topHits) }
                }
                ForEach(byFolder, id: \.name) { folder in
                    Section(folder.name) { rows(folder.items) }
                }
            }
        }
    }

    private func rows(_ items: [SavedItem]) -> some View {
        ForEach(items) { item in
            NavigationLink(value: item) { ItemCardView(item: item) }
        }
    }
}
