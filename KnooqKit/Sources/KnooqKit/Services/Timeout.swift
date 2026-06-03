import Foundation

public struct TimeoutError: Error {}

/// Runs `operation`, racing it against a timeout. If the timeout wins, throws `TimeoutError`.
/// Note: a non-cooperative operation may keep running in the background after the timeout;
/// the caller stops waiting on it.
public func withTimeout<T: Sendable>(
    seconds: Double,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(for: .seconds(seconds))
            throw TimeoutError()
        }
        defer { group.cancelAll() }
        guard let result = try await group.next() else { throw TimeoutError() }
        return result
    }
}
