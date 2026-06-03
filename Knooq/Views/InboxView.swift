import SwiftUI
import SwiftData
import KnooqKit

struct InboxView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<SavedItem> { !$0.isArchived },
           sort: \SavedItem.createdAt, order: .reverse)
    private var items: [SavedItem]

    @State private var showSettings = false
    @State private var showNewFolder = false
    @State private var newFolderName = ""
    @State private var customFolders: [String] = CategoryStore().customFolders

    private var processing: [SavedItem] { items.filter { $0.status == .pending } }
    private var needsAttention: [SavedItem] { items.filter { $0.status == .failed } }
    private var processed: [SavedItem] { items.filter { $0.status == .processed } }

    /// Folder names to show (Notes + custom + any used category), each with its processed count.
    private var folders: [(name: String, count: Int)] {
        let used = Set(processed.compactMap(\.category))
        return Folders.visible(custom: customFolders, used: used).map { name in
            (name, processed.filter { $0.category == name }.count)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Processing") {
                    if processing.isEmpty {
                        Text("Nothing processing right now")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(processing) { item in
                            NavigationLink(value: item) { ItemCardView(item: item) }
                                .swipeActions(edge: .trailing) { deleteButton(item) }
                        }
                    }
                }

                Section("Needs attention") {
                    if needsAttention.isEmpty {
                        Text("No issues")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(needsAttention) { item in
                            NavigationLink(value: item) { ItemCardView(item: item) }
                                .swipeActions(edge: .trailing) {
                                    deleteButton(item)
                                    archiveButton(item)
                                }
                        }
                    }
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
            }
            .navigationTitle("Inbox")
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

    private func addFolder() {
        var store = CategoryStore()
        store.add(newFolderName)
        customFolders = store.customFolders
        newFolderName = ""
    }

    private func deleteButton(_ item: SavedItem) -> some View {
        Button(role: .destructive) { context.delete(item) } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func archiveButton(_ item: SavedItem) -> some View {
        Button { item.isArchived = true } label: {
            Label("Archive", systemImage: "archivebox")
        }
        .tint(.blue)
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
