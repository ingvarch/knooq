import Testing
import Foundation
@testable import KnooqKit

@Suite struct ImageStoreTests {

    private func tempStore() -> (ImageStore, URL) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("imgstore-\(UUID().uuidString)")
        return (ImageStore(directory: dir), dir)
    }

    @Test func saveReturnsFilenameAndWritesFile() throws {
        let (store, _) = tempStore()
        let data = Data([0xFF, 0xD8, 0xFF])
        let filename = try store.save(data)
        #expect(filename.hasSuffix(".jpg"))
        #expect(FileManager.default.fileExists(atPath: store.url(for: filename).path))
    }

    @Test func roundTripsData() throws {
        let (store, _) = tempStore()
        let data = Data("hello".utf8)
        let filename = try store.save(data)
        #expect(try store.data(for: filename) == data)
    }

    @Test func savesAreUnique() throws {
        let (store, _) = tempStore()
        let a = try store.save(Data([1]))
        let b = try store.save(Data([2]))
        #expect(a != b)
    }

    @Test func urlIsInsideDirectory() {
        let (store, dir) = tempStore()
        let parent = store.url(for: "x.jpg").deletingLastPathComponent()
        #expect(parent.standardizedFileURL.path == dir.standardizedFileURL.path)
        #expect(store.url(for: "x.jpg").lastPathComponent == "x.jpg")
    }

    @Test func deleteRemovesFile() throws {
        let (store, _) = tempStore()
        let filename = try store.save(Data([1]))
        try store.delete(filename)
        #expect(!FileManager.default.fileExists(atPath: store.url(for: filename).path))
    }
}
