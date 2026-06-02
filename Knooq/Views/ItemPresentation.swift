import SwiftUI
import KnooqKit

// Reusable presentation mappings + small chips, shared by Inbox and Detail (DRY).

extension ItemStatus {
    var iconName: String {
        switch self {
        case .pending: "clock"
        case .processed: "checkmark.circle"
        case .failed: "exclamationmark.triangle"
        }
    }

    var tint: Color {
        switch self {
        case .pending: .orange
        case .processed: .green
        case .failed: .red
        }
    }
}

extension ItemCategory {
    var symbol: String {
        switch self {
        case .article: "doc.text"
        case .video: "play.rectangle"
        case .recipe: "fork.knife"
        case .purchase: "cart"
        case .travel: "airplane"
        case .idea: "lightbulb"
        case .tool: "wrench.and.screwdriver"
        case .other: "tray"
        }
    }
}

struct StatusBadge: View {
    let status: ItemStatus
    var body: some View {
        Image(systemName: status.iconName)
            .foregroundStyle(status.tint)
            .font(.caption)
            .accessibilityLabel("Status: \(status.rawValue)")
    }
}

struct CategoryChip: View {
    let category: ItemCategory
    var body: some View {
        Label(category.rawValue, systemImage: category.symbol)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.tint.opacity(0.15), in: Capsule())
            .foregroundStyle(.tint)
    }
}

struct TagsRow: View {
    let tags: [String]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
