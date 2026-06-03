import SwiftUI
import SwiftData
import KnooqKit

/// Navigation target for a folder: a named category or the special "All" view.
enum FolderRoute: Hashable {
    case all
    case category(String)

    var title: String {
        switch self {
        case .all: "All"
        case .category(let name): name
        }
    }
}

/// A folder view: processed items (all, or one category) grouped by day, newest first.
struct CategoryView: View {
    let route: FolderRoute

    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<SavedItem> { !$0.isArchived },
           sort: \SavedItem.createdAt, order: .reverse)
    private var all: [SavedItem]

    private var items: [SavedItem] {
        all.filter { item in
            guard item.status == .processed else { return false }
            switch route {
            case .all: return true
            case .category(let name): return item.category == name
            }
        }
    }

    private var groupedByDay: [(day: Date, items: [SavedItem])] {
        let groups = Dictionary(grouping: items) { Calendar.current.startOfDay(for: $0.createdAt) }
        return groups
            .map { (day: $0.key, items: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        List {
            ForEach(groupedByDay, id: \.day) { group in
                Section(group.day.formatted(date: .abbreviated, time: .omitted)) {
                    ForEach(group.items) { item in
                        NavigationLink(value: item) { ItemCardView(item: item) }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { context.delete(item) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { item.isArchived = true } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("Empty", systemImage: "folder",
                                       description: Text("Nothing here yet."))
            }
        }
    }
}
