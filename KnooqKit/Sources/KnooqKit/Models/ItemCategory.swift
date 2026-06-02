import Foundation

/// Fixed v1 category set — single source of truth for FM guides, UI chips, and validation (DRY).
/// Named `ItemCategory` (not `Category`) to avoid clashing with the global ObjC `Category` type.
public enum ItemCategory: String, CaseIterable, Codable, Sendable {
    case article = "Article"
    case video = "Video"
    case recipe = "Recipe"
    case purchase = "Purchase"
    case travel = "Travel"
    case idea = "Idea"
    case tool = "Tool"
    case other = "Other"

    /// Maps an arbitrary FM-produced string to a known category, falling back to `.other`.
    public static func validated(_ input: String) -> ItemCategory {
        ItemCategory(rawValue: input) ?? .other
    }
}
