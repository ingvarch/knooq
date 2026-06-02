import Foundation

/// A raw capture handed off from the Share Extension. Plain Codable value — no SwiftData.
public struct PendingCapture: Codable, Sendable, Equatable {
    public let rawType: RawType
    public let urlString: String?
    public let text: String?
    public let imageFilename: String?
    public let createdAt: Date
    public let note: String?   // optional user-entered title from the share card

    public init(rawType: RawType, urlString: String?, text: String?, imageFilename: String?, createdAt: Date, note: String? = nil) {
        self.rawType = rawType
        self.urlString = urlString
        self.text = text
        self.imageFilename = imageFilename
        self.createdAt = createdAt
        self.note = note
    }
}

/// App Group file queue. The extension enqueues instantly (one small JSON write, no SwiftData/
/// CloudKit init — that heavy work would stall the extension). The app drains into SwiftData on launch.
public struct CaptureQueue: Sendable {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public static func appGroup() -> CaptureQueue {
        let root = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: KnooqShared.appGroupID)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return CaptureQueue(directory: root.appendingPathComponent("Pending", isDirectory: true))
    }

    public func enqueue(_ capture: PendingCapture) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(capture)
        try data.write(to: directory.appendingPathComponent("\(UUID().uuidString).json"), options: .atomic)
    }

    /// Reads and removes all queued captures, oldest first.
    public func drain() throws -> [PendingCapture] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        var captures: [PendingCapture] = []
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let capture = try? JSONDecoder().decode(PendingCapture.self, from: data) else { continue }
            captures.append(capture)
            try? FileManager.default.removeItem(at: file)
        }
        return captures.sorted { $0.createdAt < $1.createdAt }
    }
}
