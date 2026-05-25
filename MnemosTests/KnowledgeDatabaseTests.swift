import Testing
import Foundation
@testable import Mnemos

@MainActor
@Suite struct KnowledgeDatabaseTests {
    private func makeDB() throws -> KnowledgeDatabase {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString + ".db")
        return try KnowledgeDatabase(url: url)
    }

    @Test func insertAndFetchByDateKey() throws {
        let db = try makeDB()
        let snippet = KnowledgeSnippet(content: "hello", tags: ["swift"])
        try db.insert(snippet)
        let key = String(snippet.capturedAt.ISO8601Format().prefix(10))
        let results = db.fetchByDateKey(key)
        #expect(results.count == 1)
        #expect(results[0].id == snippet.id)
        #expect(results[0].content == "hello")
        #expect(results[0].tags == ["swift"])
    }

    @Test func insertOrIgnoreSkipsDuplicates() throws {
        let db = try makeDB()
        let snippet = KnowledgeSnippet(content: "dup", tags: [])
        try db.insert(snippet)
        try db.insert(snippet)
        let all = db.fetchAllGroupedByDate()
        #expect(all.flatMap(\.items).count == 1)
    }

    @Test func fetchAllGroupedByDateReturnsChronologicalLogs() throws {
        let db = try makeDB()
        let cal = Calendar.current
        let today = Date.now
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let s1 = KnowledgeSnippet(content: "today", tags: [], capturedAt: today)
        let s2 = KnowledgeSnippet(content: "yesterday", tags: [], capturedAt: yesterday)
        try db.insert(s1)
        try db.insert(s2)
        let logs = db.fetchAllGroupedByDate()
        #expect(logs.count == 2)
        #expect(logs[0].date < logs[1].date)
    }

    @Test func fetchByTagReturnsOnlyMatchingSnippets() throws {
        let db = try makeDB()
        let swift = KnowledgeSnippet(content: "swift tip", tags: ["swift"])
        let python = KnowledgeSnippet(content: "python tip", tags: ["python"])
        try db.insert(swift)
        try db.insert(python)
        let results = db.fetchByTag("swift")
        #expect(results.count == 1)
        #expect(results[0].id == swift.id)
    }

    @Test func purgeExpiredRemovesOldSnippets() throws {
        let db = try makeDB()
        let expired = KnowledgeSnippet(
            content: "old",
            tags: [],
            capturedAt: Date(timeIntervalSinceNow: -8 * 24 * 3600)
        )
        let fresh = KnowledgeSnippet(content: "new", tags: [])
        try db.insert(expired)
        try db.insert(fresh)
        db.purgeExpired(before: .now)
        let all = db.fetchAllGroupedByDate().flatMap(\.items)
        #expect(all.count == 1)
        #expect(all[0].id == fresh.id)
    }

    @Test func ftsSearchMatchesContent() throws {
        let db = try makeDB()
        let hit = KnowledgeSnippet(content: "dependency injection pattern", tags: [])
        let miss = KnowledgeSnippet(content: "unrelated entry", tags: [])
        try db.insert(hit)
        try db.insert(miss)
        let results = db.search(query: "injection")
        #expect(results.count == 1)
        #expect(results[0].id == hit.id)
    }

    @Test func deleteAllClearsTable() throws {
        let db = try makeDB()
        try db.insert(KnowledgeSnippet(content: "a", tags: []))
        try db.insert(KnowledgeSnippet(content: "b", tags: []))
        db.deleteAll()
        #expect(db.fetchAllGroupedByDate().isEmpty)
    }

    @Test func allTagsDeduplicatesAcrossSnippets() throws {
        let db = try makeDB()
        try db.insert(KnowledgeSnippet(content: "one", tags: ["swift", "ios"]))
        try db.insert(KnowledgeSnippet(content: "two", tags: ["swift", "macos"]))
        let tags = db.allTags()
        #expect(tags == ["ios", "macos", "swift"])
    }
}
