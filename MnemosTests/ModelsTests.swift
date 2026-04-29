import Testing
import Foundation
@testable import Mnemos

struct KnowledgeSnippetTests {

    @Test func roundTripsJSON() throws {
        let snippet = KnowledgeSnippet(content: "Use @MainActor for UI classes", tags: ["swift", "concurrency"])
        let data = try JSONEncoder().encode(snippet)
        let decoded = try JSONDecoder().decode(KnowledgeSnippet.self, from: data)
        #expect(decoded.id == snippet.id)
        #expect(decoded.content == snippet.content)
        #expect(decoded.tags == snippet.tags)
        #expect(decoded.capturedAt == snippet.capturedAt)
        #expect(decoded.expiresAt == snippet.expiresAt)
    }

    @Test func expiresAtIsSevenDaysAfterCapturedAt() {
        let snippet = KnowledgeSnippet(content: "test", tags: [])
        let diff = snippet.expiresAt.timeIntervalSince(snippet.capturedAt)
        #expect(diff == 7 * 24 * 60 * 60)
    }

    @Test func emptyTagsRoundTrip() throws {
        let snippet = KnowledgeSnippet(content: "no tags", tags: [])
        let data = try JSONEncoder().encode(snippet)
        let decoded = try JSONDecoder().decode(KnowledgeSnippet.self, from: data)
        #expect(decoded.tags.isEmpty)
    }

    @Test func uniqueIDsPerInstance() {
        let a = KnowledgeSnippet(content: "same", tags: [])
        let b = KnowledgeSnippet(content: "same", tags: [])
        #expect(a.id != b.id)
    }
}

struct DailyLogTests {

    @Test func roundTripsJSON() throws {
        let log = DailyLog(
            date: "2026-04-29",
            items: [KnowledgeSnippet(content: "entry", tags: ["tag"])]
        )
        let data = try JSONEncoder().encode(log)
        let decoded = try JSONDecoder().decode(DailyLog.self, from: data)
        #expect(decoded.date == log.date)
        #expect(decoded.items.count == log.items.count)
        #expect(decoded.items[0].id == log.items[0].id)
    }

    @Test func emptyItemsRoundTrip() throws {
        let log = DailyLog(date: "2026-04-29", items: [])
        let data = try JSONEncoder().encode(log)
        let decoded = try JSONDecoder().decode(DailyLog.self, from: data)
        #expect(decoded.items.isEmpty)
    }

    @Test func dateFormatIsYYYYMMDD() {
        let log = DailyLog(date: "2026-04-29", items: [])
        let parts = log.date.split(separator: "-")
        #expect(parts.count == 3)
        #expect(parts[0].count == 4) // YYYY
        #expect(parts[1].count == 2) // MM
        #expect(parts[2].count == 2) // DD
    }
}
