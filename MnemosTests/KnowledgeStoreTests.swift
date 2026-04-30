import Testing
import Foundation
@testable import Mnemos

@MainActor
struct KnowledgeStoreTests {

    private func makeStore() -> KnowledgeStore {
        let tmp = FileManager.default.temporaryDirectory
            .appending(path: "MnemosTests-\(UUID().uuidString)")
        return KnowledgeStore(directory: tmp)
    }

    @Test func savePersistsSnippetToFile() throws {
        let store = makeStore()
        let snippet = KnowledgeSnippet(content: "hello", tags: ["swift"])
        try store.save(snippet)
        let log = try #require(store.fetchToday())
        #expect(log.items.count == 1)
        #expect(log.items[0].id == snippet.id)
    }

    @Test func saveAppendsToExistingLog() throws {
        let store = makeStore()
        try store.save(KnowledgeSnippet(content: "first", tags: []))
        try store.save(KnowledgeSnippet(content: "second", tags: []))
        let log = try #require(store.fetchToday())
        #expect(log.items.count == 2)
    }

    @Test func fetchTodayReturnsNilWhenNoFile() {
        let store = makeStore()
        #expect(store.fetchToday() == nil)
    }

    @Test func fetchAllReturnsAllLogs() throws {
        let store = makeStore()
        let yesterday = Date.now.addingTimeInterval(-86400)
        let snippetYesterday = KnowledgeSnippet(content: "yesterday", tags: [], capturedAt: yesterday)
        let snippetToday = KnowledgeSnippet(content: "today", tags: [])
        try store.save(snippetYesterday)
        try store.save(snippetToday)
        let all = store.fetchAll()
        #expect(all.count == 2)
        #expect(all[0].date < all[1].date)
    }

    @Test func atomicWriteLeavesNoTempFiles() throws {
        let store = makeStore()
        try store.save(KnowledgeSnippet(content: "atomic", tags: []))
        let contents = try FileManager.default.contentsOfDirectory(atPath: store.directory.path())
        #expect(contents.allSatisfy { $0.hasSuffix(".json") })
    }

    @Test func savedDataRoundTrips() throws {
        let store = makeStore()
        let snippet = KnowledgeSnippet(content: "round trip", tags: ["a", "b"])
        try store.save(snippet)
        let log = try #require(store.fetchToday())
        let loaded = log.items[0]
        #expect(loaded.content == snippet.content)
        #expect(loaded.tags == snippet.tags)
        #expect(loaded.expiresAt == snippet.expiresAt)
    }
}
