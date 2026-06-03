import SwiftUI
import SwiftData
import KnooqKit

struct InboxView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<SavedItem> { !$0.isArchived },
           sort: \SavedItem.createdAt, order: .reverse)
    private var items: [SavedItem]

    @State private var showSettings = false

    private var processing: [SavedItem] { items.filter { $0.status == .pending } }
    private var needsAttention: [SavedItem] { items.filter { $0.status == .failed } }
    private var processed: [SavedItem] { items.filter { $0.status == .processed } }

    /// Categories that currently contain at least one processed item, in canonical order.
    private var folders: [(category: ItemCategory, count: Int)] {
        ItemCategory.allCases.compactMap { category in
            let count = processed.filter { $0.category == category }.count
            return count > 0 ? (category, count) : nil
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

                if !folders.isEmpty {
                    Section("Folders") {
                        ForEach(folders, id: \.category) { folder in
                            NavigationLink(value: folder.category) {
                                Label {
                                    HStack {
                                        Text(folder.category.rawValue)
                                        Spacer()
                                        Text("\(folder.count)").foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: folder.category.symbol)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Inbox")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .navigationDestination(for: ItemCategory.self) { category in
                CategoryView(category: category)
            }
            .navigationDestination(for: SavedItem.self) { item in
                ItemDetailView(item: item)
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
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
