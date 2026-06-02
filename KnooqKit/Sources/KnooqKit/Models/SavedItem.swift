import Foundation
import SwiftData

/// The single domain entity. A status state machine drives the pipeline:
/// extension writes raw payload as `.pending`; main app fills FM results and sets `.processed`.
@Model
public final class SavedItem {
    // Defaults are required for non-optional attributes under SwiftData + CloudKit.
    public var id: UUID = UUID()
    public var createdAt: Date = Date.now
    public var status: ItemStatus = ItemStatus.pending

    // Raw payload (written by the Share Extension).
    public var rawType: RawType = RawType.text
    public var rawURL: URL?
    public var rawText: String?
    public var imageFilename: String?   // file in App Group, not a DB blob

    // FM analysis results (written by the main app).
    public var category: ItemCategory?
    public var tags: [String] = []
    public var summary: String?
    public var title: String?
    public var userTitled: Bool = false   // true when the user typed the title; FM won't overwrite it

    // Diagnostics: why the last processing attempt failed (nil when not failed).
    public var failureReason: String?

    // Nudge mechanics.
    public var lastNudgedAt: Date?
    public var isArchived: Bool = false
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
