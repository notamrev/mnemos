import Testing
import Foundation
@testable import Mnemos

@MainActor
struct RollingExpiryTests {

    private func makeStore() -> KnowledgeStore {
        let tmp = FileManager.default.temporaryDirectory
            .appending(path: "MnemosExpiry-\(UUID().uuidString)")
        return KnowledgeStore(directory: tmp)
    }

    @Test func purgeDeletesFilesOlderThanSevenDays() throws {
        let store = makeStore()
        let eightDaysAgo = Date.now.addingTimeInterval(-8 * 86400)
        let old = KnowledgeSnippet(content: "old", tags: [], capturedAt: eightDaysAgo)
        try store.save(old)
        store.purgeExpired()
        #expect(store.fetchAll().isEmpty)
    }

    @Test func purgeKeepsFilesWithinSevenDays() throws {
        let store = makeStore()
        let sixDaysAgo = Date.now.addingTimeInterval(-6 * 86400)
        let recent = KnowledgeSnippet(content: "recent", tags: [], capturedAt: sixDaysAgo)
        try store.save(recent)
        store.purgeExpired()
        #expect(store.fetchAll().count == 1)
    }

    @Test func purgeRemovesExpiredSnippetsWithinCurrentFile() throws {
        let store = makeStore()
        // expired snippet: expiresAt in the past
        let longAgo = Date.now.addingTimeInterval(-10 * 86400)
        let expired = KnowledgeSnippet(content: "expired", tags: [], capturedAt: longAgo)
        let valid = KnowledgeSnippet(content: "valid", tags: [])
        let today = store.dateKey(for: .now)
        let url = store.directory.appending(path: "\(today).json")
        let log = DailyLog(date: today, items: [expired, valid])
        let data = try JSONEncoder().encode(log)
        try data.write(to: url)
        store.purgeExpired()
        let result = try #require(store.fetchToday())
        #expect(result.items.count == 1)
        #expect(result.items[0].content == "valid")
    }

    @Test func purgeKeepsTodayFileIntact() throws {
        let store = makeStore()
        try store.save(KnowledgeSnippet(content: "today", tags: []))
        store.purgeExpired()
        #expect(store.fetchToday() != nil)
    }
}
