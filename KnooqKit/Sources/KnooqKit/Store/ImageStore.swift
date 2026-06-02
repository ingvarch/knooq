import Foundation

/// File store for captured images, living in the App Group container.
/// The extension writes; the main app reads (OCR + thumbnails). One path policy, shared (DRY).
/// The DB holds only the filename — never the blob.
public struct ImageStore: Sendable {
    private let directory: URL

    /// Inject a directory directly (used in tests).
    public init(directory: URL) {
        self.directory = directory
    }

    /// Shared store: <AppGroup>/Images when entitled (extension + app see the same files),
    /// else a local Application Support/Images fallback so dev/unsigned builds still run.
    public static func appGroup() -> ImageStore {
        let root = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: KnooqShared.appGroupID)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return ImageStore(directory: root.appendingPathComponent("Images", isDirectory: true))
    }

    public func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }

    /// Writes image data under a fresh unique filename and returns it.
    @discardableResult
    public func save(_ data: Data) throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = "\(UUID().uuidString).jpg"
        try data.write(to: url(for: filename), options: .atomic)
        return filename
    }

    public func data(for filename: String) throws -> Data {
        try Data(contentsOf: url(for: filename))
    }

    public func delete(_ filename: String) throws {
        try FileManager.default.removeItem(at: url(for: filename))
    }
}
