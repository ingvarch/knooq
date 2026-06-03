import SwiftUI
import KnooqKit

// Reusable presentation mappings + small chips, shared by Inbox and Detail (DRY).

extension SavedItem {
    /// Description = user note with the FM summary appended (FM appends, never overwrites the note).
    var displayDescription: String? {
        let parts = [note, summary].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: "\n\n")
    }
}

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

/// Trailing status accessory: a large spinner while processing, nothing when done,
/// a red warning if it failed.
struct StatusBadge: View {
    let status: ItemStatus
    var body: some View {
        switch status {
        case .pending:
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.6)
                .accessibilityLabel("Processing")
        case .processed:
            EmptyView()
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.title3)
                .accessibilityLabel("Failed")
        }
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
