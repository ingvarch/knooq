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
    @State private var foldersExpanded = true
    @State private var tagsExpanded = true
    @State private var path = NavigationPath()
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
        NavigationStack(path: $path) {
            Group {
                if searchText.isEmpty {
                    inboxList
                } else {
                    SearchResultsView(query: searchText, items: items)
                }
            }
            .navigationTitle("Inbox")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: path) { _, _ in
                // A folder may have been deleted from its detail menu; re-read custom folders on return.
                customFolders = CategoryStore().customFolders
            }
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

            Section {
                if foldersExpanded {
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
                        .swipeActions(edge: .trailing) {
                            if customFolders.contains(folder.name) {
                                Button(role: .destructive) { deleteFolder(folder.name) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            } header: {
                sectionHeader("Folders", $foldersExpanded)
            }

            if !allTags.isEmpty {
                Section {
                    if tagsExpanded { tagCloud }
                } header: {
                    sectionHeader("Tags", $tagsExpanded)
                }
            }
        }
        .refreshable { await onRefresh() }
    }

    private func sectionHeader(_ title: String, _ expanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(.snappy) { expanded.wrappedValue.toggle() }
        } label: {
            HStack {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(expanded.wrappedValue ? 0 : -90))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .textCase(nil)
    }

    /// Tag "cloud": tappable chips wrapped in a flow layout (buttons, so no list chevrons).
    private var tagCloud: some View {
        FlowLayout(spacing: 8) {
            cloudChip("All Tags") { path.append(TagSelection.allTagged) }
            ForEach(allTags, id: \.self) { tag in
                cloudChip("#\(tag)") { path.append(TagSelection.includingTag(tag)) }
            }
        }
    }

    private func cloudChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    private func addFolder() {
        var store = CategoryStore()
        store.add(newFolderName)
        customFolders = store.customFolders
        newFolderName = ""
    }

    /// Delete a user-created folder; its items move to Other so they aren't lost.
    private func deleteFolder(_ name: String) {
        for item in items where item.category == name {
            item.category = Categories.other
        }
        try? context.save()
        var store = CategoryStore()
        store.remove(name)
        customFolders = store.customFolders
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
