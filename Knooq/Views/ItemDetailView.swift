import SwiftUI
import SwiftData
import KnooqKit

struct ItemDetailView: View {
    @Bindable var item: SavedItem
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var isEditingTags = false
    @State private var newTag = ""
    @State private var confirmingDelete = false

    /// Category edits route through `setCategory` so `openedAt` stamping stays in one place (DRY).
    private var categoryBinding: Binding<ItemCategory?> {
        Binding(get: { item.category }, set: { item.setCategory($0) })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                categorySection
                tagsSection
                if let description = item.displayDescription {
                    section("Description") { Text(description).font(.body) }
                }
                if let url = item.rawURL {
                    Link(destination: url) {
                        Label("Open Original", systemImage: "safari").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    LinkPreview(url: url)
                }
                if let filename = item.imageFilename {
                    ImagePreview(filename: filename)
                }
                actions
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this item?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(item)
                dismiss()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title ?? "Untitled").font(.title.bold())
            HStack {
                StatusBadge(status: item.status)
                Text(item.createdAt, style: .relative).foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }

    private var categorySection: some View {
        section("Category") {
            Picker("Category", selection: categoryBinding) {
                Text("None").tag(ItemCategory?.none)
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(ItemCategory?.some(category))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var tagsSection: some View {
        section("Tags", trailing: Button(isEditingTags ? "Done" : "Edit") { isEditingTags.toggle() }) {
            FlowLayout(spacing: 8) {
                ForEach(item.tags, id: \.self) { tag in
                    EditableTagChip(tag: tag, isEditing: isEditingTags) { item.removeTag(tag) }
                }
                if isEditingTags {
                    AddTagField(text: $newTag) {
                        item.addTag(newTag)
                        newTag = ""
                    }
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 16) {
            Button(item.isArchived ? "Unarchive" : "Archive") { item.toggleArchive() }
                .buttonStyle(.bordered)
            Button("Delete", role: .destructive) { confirmingDelete = true }
                .buttonStyle(.bordered)
        }
    }

    private func section<Content: View>(
        _ title: String,
        trailing: (some View)? = Optional<EmptyView>.none,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                trailing
            }
            content()
        }
    }
}

struct EditableTagChip: View {
    let tag: String
    let isEditing: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)").font(.caption)
            if isEditing {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill").font(.caption2)
                }
                .accessibilityLabel("Remove tag \(tag)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary, in: Capsule())
    }
}

struct AddTagField: View {
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        TextField("add tag", text: $text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .frame(width: 90)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary, in: Capsule())
            .onSubmit(onSubmit)
    }
}

struct ImagePreview: View {
    let filename: String

    var body: some View {
        if let uiImage = UIImage(contentsOfFile: ImageStore.appGroup().url(for: filename).path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
                .frame(height: 160)
                .overlay { Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary) }
        }
    }
}

/// Wrapping layout for tag chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(maxWidth, widest), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ItemDetailView(item: PreviewData.samples[0])
    }
    .modelContainer(PreviewData.container)
}
#endif
