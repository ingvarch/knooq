#if DEBUG
import SwiftData
import Foundation
import KnooqKit

/// In-memory container with sample items, for SwiftUI previews only.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let container = try! KnooqStore.container(inMemory: true)
        let context = container.mainContext
        for item in samples { context.insert(item) }
        return container
    }()

    static var samples: [SavedItem] {
        let a = SavedItem(rawType: .url, rawURL: URL(string: "https://swift.org"))
        a.status = .processed; a.category = .article; a.tags = ["swift", "ios"]
        a.title = "Swift Concurrency Guide"; a.summary = "A practical tour of async/await and actors."

        let b = SavedItem(rawType: .text, rawText: "pasta")
        b.status = .pending; b.title = "Carbonara"

        let c = SavedItem(rawType: .image, imageFilename: "x.jpg")
        c.status = .processed; c.category = .recipe; c.tags = ["dinner", "italian"]
        c.title = "Weeknight Pasta"; c.summary = "Fast 20-minute pasta."

        return [a, b, c]
    }
}
#endif
