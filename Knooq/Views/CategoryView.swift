import SwiftUI
import SwiftData
import KnooqKit

/// Navigation target for a folder: a named category, the special "All" view, or a status bucket.
enum FolderRoute: Hashable {
    case all
    case processing
    case needsAttention
    case category(String)

    var title: String {
        switch self {
        case .all: "All"
        case .processing: "Processing"
        case .needsAttention: "Needs attention"
        case .category(let name): name
        }
    }
}

/// A folder view: its items, sortable, with a per-folder settings menu (sort + delete).
struct CategoryView: View {
    let route: FolderRoute

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<SavedItem> { !$0.isArchived },
           sort: \SavedItem.createdAt, order: .reverse)
    private var all: [SavedItem]

    @State private var sort = ItemSort()

    private var filtered: [SavedItem] {
        all.filter { item in
            switch route {
            case .all: return item.status == .processed
            case .processing: return item.status == .pending
            case .needsAttention: return item.status == .failed
            case .category(let name): return item.status == .processed && item.category == name
            }
        }
    }

    /// Date-sorted views group by Today/Yesterday/month/year; Title sort is a flat list.
    private var sections: [(title: String?, items: [SavedItem])] {
        switch sort.field {
        case .title:
            return [(nil, ItemSorting.sorted(filtered, by: sort))]
        case .dateCreated:
            return DateGrouping.group(filtered, dateFor: { $0.createdAt }, now: .now, ascending: sort.order == .oldestFirst)
                .map { ($0.title, $0.items) }
        case .dateEdited:
            return DateGrouping.group(filtered, dateFor: { ItemSorting.editedDate($0) }, now: .now, ascending: sort.order == .oldestFirst)
                .map { ($0.title, $0.items) }
        }
    }

    /// The folder name if this is a user-created (deletable) folder.
    private var customFolderName: String? {
        if case .category(let name) = route, CategoryStore().customFolders.contains(name) { return name }
        return nil
    }

    var body: some View {
        List {
            ForEach(sections, id: \.title) { section in
                Section {
                    ForEach(section.items) { item in
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
                } header: {
                    if let title = section.title { Text(title) }
                }
            }
        }
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { folderMenu }
        }
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView("Empty", systemImage: "folder",
                                       description: Text("Nothing here yet."))
            }
        }
    }

    private var folderMenu: some View {
        Menu {
            Picker("Sort by", selection: $sort.field) {
                Text("Date Edited").tag(ItemSortField.dateEdited)
                Text("Date Created").tag(ItemSortField.dateCreated)
                Text("Title").tag(ItemSortField.title)
            }
            Picker("Order", selection: $sort.order) {
                Text("Newest First").tag(ItemSortOrder.newestFirst)
                Text("Oldest First").tag(ItemSortOrder.oldestFirst)
            }
            if let name = customFolderName {
                Divider()
                Button(role: .destructive) { deleteFolder(name) } label: {
                    Label("Delete Folder", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    /// Delete the folder; its items move to Other so they aren't lost. Pops back.
    private func deleteFolder(_ name: String) {
        for item in all where item.category == name {
            item.category = Categories.other
        }
        try? context.save()
        var store = CategoryStore()
        store.remove(name)
        dismiss()
    }
}
