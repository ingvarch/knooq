import SwiftUI
import SwiftData
import KnooqKit

struct InboxView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<SavedItem> { !$0.isArchived },
           sort: \SavedItem.createdAt, order: .reverse)
    private var items: [SavedItem]

    @State private var selectedCategory: ItemCategory?
    @State private var selectedTag: String?

    private var filtered: [SavedItem] {
        ItemFilter.apply(items, category: selectedCategory, tag: selectedTag)
    }

    var body: some View {
        NavigationStack {
            List {
                FilterChipsView(
                    tags: ItemFilter.allTags(items),
                    selectedCategory: $selectedCategory,
                    selectedTag: $selectedTag
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)

                ForEach(filtered) { item in
                    NavigationLink(value: item) {
                        ItemCardView(item: item)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            context.delete(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            item.isArchived = true
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.blue)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Inbox")
            .overlay {
                if filtered.isEmpty {
                    ContentUnavailableView("Nothing saved yet",
                                           systemImage: "tray",
                                           description: Text("Share a link, image, or text to Knooq."))
                }
            }
            .navigationDestination(for: SavedItem.self) { item in
                ItemDetailView(item: item)
            }
        }
    }
}

struct ItemCardView: View {
    let item: SavedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(item.title ?? "Untitled")
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                StatusBadge(status: item.status)
            }
            if let category = item.category {
                CategoryChip(category: category)
            }
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
        .padding(.vertical, 4)
    }
}

/// Horizontal category + tag filter chips with single-select toggle.
struct FilterChipsView: View {
    let tags: [String]
    @Binding var selectedCategory: ItemCategory?
    @Binding var selectedTag: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All", systemImage: "tray.full",
                               isOn: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        FilterChip(label: category.rawValue,
                                   systemImage: category.symbol,
                                   isOn: selectedCategory == category) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.horizontal)
            }
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            FilterChip(label: "#\(tag)", systemImage: nil,
                                       isOn: selectedTag == tag) {
                                selectedTag = selectedTag == tag ? nil : tag
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let label: String
    let systemImage: String?
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage { Image(systemName: systemImage) }
                Text(label)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary), in: Capsule())
            .foregroundStyle(isOn ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    InboxView()
        .modelContainer(PreviewData.container)
}
#endif
