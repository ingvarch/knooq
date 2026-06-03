import SwiftUI
import SwiftData
import KnooqKit

struct InboxView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<SavedItem> { !$0.isArchived },
           sort: \SavedItem.createdAt, order: .reverse)
    private var items: [SavedItem]

    /// Pull-to-refresh action — re-imports and retries failed items (Needs attention).
    var onRefresh: () async -> Void = {}

    @State private var showSettings = false
    @State private var showNewFolder = false
    @State private var newFolderName = ""
    @State private var searchText = ""
    @State private var customFolders: [String] = CategoryStore().customFolders

    private var processing: [SavedItem] { items.filter { $0.status == .pending } }
    private var needsAttention: [SavedItem] { items.filter { $0.status == .failed } }
    private var processed: [SavedItem] { items.filter { $0.status == .processed } }
    private var allTags: [String] { ItemFilter.allTags(processed) }

    /// Folder names to show (Notes + custom + any used category), each with its processed count.
    private var folders: [(name: String, count: Int)] {
        let used = Set(processed.compactMap(\.category))
        return Folders.visible(custom: customFolders, used: used).map { name in
            (name, processed.filter { $0.category == name }.count)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    inboxList
                } else {
                    SearchResultsView(query: searchText, items: items)
                }
            }
            .navigationTitle(searchText.isEmpty ? "Inbox" : "Search")
            .safeAreaInset(edge: .bottom) { searchBar }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewFolder = true } label: { Image(systemName: "folder.badge.plus") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .navigationDestination(for: FolderRoute.self) { route in
                CategoryView(route: route)
            }
            .navigationDestination(for: TagSelection.self) { selection in
                TagFilterView(initial: selection)
            }
            .navigationDestination(for: SavedItem.self) { item in
                ItemDetailView(item: item)
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .alert("New folder", isPresented: $showNewFolder) {
                TextField("Folder name", text: $newFolderName)
                Button("Cancel", role: .cancel) { newFolderName = "" }
                Button("Add") { addFolder() }
            } message: {
                Text("Create a folder you can move items into.")
            }
        }
    }

    private var inboxList: some View {
        List {
            Section {
                statusRow(.processing, "Processing", "arrow.triangle.2.circlepath", count: processing.count)
                statusRow(.needsAttention, "Needs attention", "exclamationmark.triangle", count: needsAttention.count)
            }

            Section("Folders") {
                NavigationLink(value: FolderRoute.all) {
                    Label("All", systemImage: "tray.full")
                }
                ForEach(folders, id: \.name) { folder in
                    NavigationLink(value: FolderRoute.category(folder.name)) {
                        Label {
                            HStack {
                                Text(folder.name)
                                Spacer()
                                Text("\(folder.count)").foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: categorySymbol(folder.name))
                        }
                    }
                }
            }

            if !allTags.isEmpty {
                Section("Tags") {
                    NavigationLink(value: TagSelection.allTagged) {
                        Label("All Tags", systemImage: "tag")
                    }
                    ForEach(allTags, id: \.self) { tag in
                        NavigationLink(value: TagSelection.includingTag(tag)) {
                            Label("#\(tag)", systemImage: "number")
                        }
                    }
                }
            }
        }
        .refreshable { await onRefresh() }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.quaternary))
        .padding(.horizontal)
        .padding(.bottom, 6)
    }

    private func addFolder() {
        var store = CategoryStore()
        store.add(newFolderName)
        customFolders = store.customFolders
        newFolderName = ""
    }

    private func statusRow(_ route: FolderRoute, _ title: String, _ symbol: String, count: Int) -> some View {
        NavigationLink(value: route) {
            Label {
                HStack {
                    Text(title)
                    Spacer()
                    Text("\(count)").foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: symbol)
            }
        }
    }
}

struct ItemCardView: View {
    let item: SavedItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title ?? "Untitled")
                    .font(.headline)
                    .lineLimit(2)
                if !item.tags.isEmpty {
                    TagsRow(tags: item.tags)
                }
                if let description = item.displayDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if item.status == .failed, let reason = item.failureReason {
                    Label(reason, systemImage: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            StatusBadge(status: item.status)
                .padding(.trailing, 4)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    InboxView()
        .modelContainer(PreviewData.container)
}
#endif
