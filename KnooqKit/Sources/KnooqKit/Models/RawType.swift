import Foundation

/// Kind of raw payload captured by the Share Extension.
public enum RawType: String, Codable, CaseIterable, Sendable {
    case url
    case image
    case text
}
