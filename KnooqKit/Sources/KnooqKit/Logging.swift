import os

private let knooqLogger = Logger(subsystem: "app.knooq.ios", category: "pipeline")

/// App-wide logging via os.Logger — visible in Console.app and device logs (even in release),
/// not just the Xcode debugger.
public func knooqLog(_ message: @autoclosure () -> String) {
    let text = message()
    knooqLogger.log("\(text, privacy: .public)")
}
