import Foundation

/// Lightweight DEBUG-only console logging. No-op in release.
public func knooqLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print("[Knooq] \(message())")
    #endif
}
