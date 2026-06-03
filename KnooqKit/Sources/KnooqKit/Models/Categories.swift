import Foundation

/// Categories are plain folder names (strings). A few are special:
/// - `Categories.notes` is a mandatory folder that always exists.
/// - `Categories.other` is the AI's fallback when nothing fits.
/// - `Categories.suggestions` are built-in names the AI may choose (created lazily when first used).
/// Users create their own folders on top of these (see `CategoryStore`).
public enum Categories {
    public static let notes = "Notes"
    public static let other = "Other"

    /// Built-in suggestions offered to the AI (includes Other as the fallback).
    public static let suggestions = [
        "Article", "Video", "Recipe", "Purchase", "Travel", "Idea", "Tool", other,
    ]

    /// Snaps a raw AI category to the allowed set (case-insensitive), falling back to `other`.
    public static func validated(_ raw: String, allowed: [String]) -> String {
        allowed.first { $0.caseInsensitiveCompare(raw) == .orderedSame } ?? other
    }
}
