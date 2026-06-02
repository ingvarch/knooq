import Foundation

/// Abstracts "now" so time-dependent logic (nudge staleness, anti-spam) is testable.
/// Named `DateProvider` to avoid clashing with the standard library `Clock` protocol.
public protocol DateProvider: Sendable {
    var now: Date { get }
}

public struct SystemDateProvider: DateProvider {
    public init() {}
    public var now: Date { .now }
}
