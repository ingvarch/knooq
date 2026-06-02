import Foundation

/// Pipeline state machine: pending -> processed -> (failed -> retry next launch).
public enum ItemStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case processed
    case failed
}
