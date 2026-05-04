import Testing
import Foundation
@testable import Mnemos

struct BrowseViewModelTests {

    // MARK: - groupSections

    @Test func groupSectionsEmptyLogsReturnsEmpty() {
        let result = BrowseViewModel.groupSections(logs: [], now: .now)
        #expect(result.isEmpty)
    }

    @Test func groupSectionsSortsNewestDayFirst() {
        let older = DailyLog(date: "2026-05-01", items: [snippet("older")])
        let newer = DailyLog(date: "2026-05-03", items: [snippet("newer")])
        let result = BrowseViewModel.groupSections(logs: [older, newer], now: .now)
        #expect(result[0].snippets.first?.content == "newer")
        #expect(result[1].snippets.first?.content == "older")
    }

    @Test func groupSectionsSortsSnippetsNewestFirst() {
        let t1 = date(minutesAgo: 60)
        let t2 = date(minutesAgo: 10)
        let s1 = KnowledgeSnippet(content: "first", tags: [], capturedAt: t1)
        let s2 = KnowledgeSnippet(content: "second", tags: [], capturedAt: t2)
        let log = DailyLog(date: "2026-05-04", items: [s1, s2])
        let result = BrowseViewModel.groupSections(logs: [log], now: .now)
        #expect(result[0].snippets[0].content == "second")
        #expect(result[0].snippets[1].content == "first")
    }

    @Test func groupSectionsHeaderForTodayIsToday() {
        let now = date(fromString: "2026-05-04")
        let log = DailyLog(date: "2026-05-04", items: [snippet("x")])
        let result = BrowseViewModel.groupSections(logs: [log], now: now)
        #expect(result[0].header == "Today")
    }

    @Test func groupSectionsHeaderForYesterdayIsYesterday() {
        let now = date(fromString: "2026-05-04")
        let log = DailyLog(date: "2026-05-03", items: [snippet("x")])
        let result = BrowseViewModel.groupSections(logs: [log], now: now)
        #expect(result[0].header == "Yesterday")
    }

    @Test func groupSectionsHeaderForOlderIsFormattedDate() {
        let now = date(fromString: "2026-05-04")
        let log = DailyLog(date: "2026-05-01", items: [snippet("x")])
        let result = BrowseViewModel.groupSections(logs: [log], now: now)
        #expect(result[0].header == "May 1")
    }

    @Test func groupSectionsFiltersOutEmptyLogs() {
        let empty = DailyLog(date: "2026-05-04", items: [])
        let result = BrowseViewModel.groupSections(logs: [empty], now: .now)
        #expect(result.isEmpty)
    }

    // MARK: - relativeTime

    @Test func relativeTimeUnderMinuteIsJustNow() {
        let now = Date()
        let s = KnowledgeSnippet(content: "", tags: [], capturedAt: now.addingTimeInterval(-30))
        #expect(BrowseViewModel.relativeTime(for: s, now: now) == "Just now")
    }

    @Test func relativeTimeOneMinute() {
        let now = Date()
        let s = KnowledgeSnippet(content: "", tags: [], capturedAt: now.addingTimeInterval(-90))
        #expect(BrowseViewModel.relativeTime(for: s, now: now) == "1 minute ago")
    }

    @Test func relativeTimeMultipleMinutes() {
        let now = Date()
        let s = KnowledgeSnippet(content: "", tags: [], capturedAt: now.addingTimeInterval(-150))
        #expect(BrowseViewModel.relativeTime(for: s, now: now) == "2 minutes ago")
    }

    @Test func relativeTimeOneHour() {
        let now = Date()
        let s = KnowledgeSnippet(content: "", tags: [], capturedAt: now.addingTimeInterval(-3700))
        #expect(BrowseViewModel.relativeTime(for: s, now: now) == "1 hour ago")
    }

    @Test func relativeTimeMultipleHours() {
        let now = Date()
        let s = KnowledgeSnippet(content: "", tags: [], capturedAt: now.addingTimeInterval(-7400))
        #expect(BrowseViewModel.relativeTime(for: s, now: now) == "2 hours ago")
    }

    // MARK: - Helpers

    private func snippet(_ content: String) -> KnowledgeSnippet {
        KnowledgeSnippet(content: content, tags: [])
    }

    private func date(minutesAgo: Double) -> Date {
        Date().addingTimeInterval(-minutesAgo * 60)
    }

    private func date(fromString s: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f.date(from: s)!
    }
}
