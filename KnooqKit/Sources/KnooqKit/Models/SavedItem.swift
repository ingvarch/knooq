import Foundation
import SwiftData

/// The single domain entity. A status state machine drives the pipeline:
/// extension writes raw payload as `.pending`; main app fills FM results and sets `.processed`.
@Model
public final class SavedItem {
    public var id: UUID
    public var createdAt: Date
    public var status: ItemStatus

    // Raw payload (written by the Share Extension).
    public var rawType: RawType
    public var rawURL: URL?
    public var rawText: String?
    public var imageFilename: String?   // file in App Group, not a DB blob

    // FM analysis results (written by the main app).
    public var category: ItemCategory?
    public var tags: [String]
    public var summary: String?
    public var title: String?

    // Nudge mechanics.
    public var lastNudgedAt: Date?
    public var isArchived: Bool
    public var openedAt: Date?

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        status: ItemStatus = .pending,
        rawType: RawType,
        rawURL: URL? = nil,
        rawText: String? = nil,
        imageFilename: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.status = status
        self.rawType = rawType
        self.rawURL = rawURL
        self.rawText = rawText
        self.imageFilename = imageFilename
        self.tags = []
        self.isArchived = false
    }
}
