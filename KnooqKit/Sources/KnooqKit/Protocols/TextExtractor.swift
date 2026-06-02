import Foundation

/// Sendable snapshot of an item's raw payload. Lets extraction run across concurrency
/// boundaries without passing the non-Sendable @Model, and keeps extractors free of SwiftData (DIP).
public struct RawPayload: Sendable, Equatable {
    public let rawType: RawType
    public let rawURL: URL?
    public let rawText: String?
    public let imageFilename: String?

    public init(rawType: RawType, rawURL: URL?, rawText: String?, imageFilename: String?) {
        self.rawType = rawType
        self.rawURL = rawURL
        self.rawText = rawText
        self.imageFilename = imageFilename
    }

    public init(_ item: SavedItem) {
        self.init(
            rawType: item.rawType,
            rawURL: item.rawURL,
            rawText: item.rawText,
            imageFilename: item.imageFilename
        )
    }
}

/// Extracts plain text from a raw payload. Prod: routes URL/image/text; test: StubTextExtractor.
public protocol TextExtractor: Sendable {
    func extract(from payload: RawPayload) async throws -> String
}
