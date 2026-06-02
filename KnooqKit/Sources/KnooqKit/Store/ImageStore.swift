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

    /// Production store: <AppGroup>/Images.
    public static func appGroup() -> ImageStore {
        let base = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: KnooqShared.appGroupID)!
            .appendingPathComponent("Images", isDirectory: true)
        return ImageStore(directory: base)
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
