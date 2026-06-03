import Foundation
import CryptoKit
import LinkPresentation

/// Caches fetched LPLinkMetadata in memory + on disk so link previews load instantly and don't
/// hit the network every time. Keyed by SHA256 of the URL. MainActor-bound (LPLinkMetadata isn't Sendable).
@MainActor
final class LinkMetadataCache {
    static let shared = LinkMetadataCache()

    private let memory = NSCache<NSString, LPLinkMetadata>()
    private let directory: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent("LinkPreviews", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func metadata(for url: URL) -> LPLinkMetadata? {
        let key = Self.key(url)
        if let cached = memory.object(forKey: key as NSString) { return cached }
        guard let data = try? Data(contentsOf: fileURL(key)),
              let metadata = try? NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data)
        else { return nil }
        memory.setObject(metadata, forKey: key as NSString)
        return metadata
    }

    func store(_ metadata: LPLinkMetadata, for url: URL) {
        let key = Self.key(url)
        memory.setObject(metadata, forKey: key as NSString)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true) {
            try? data.write(to: fileURL(key), options: .atomic)
        }
    }

    private func fileURL(_ key: String) -> URL {
        directory.appendingPathComponent(key)
    }

    private static func key(_ url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
