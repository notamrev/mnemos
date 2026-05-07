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

    @Test func groupSectionsSortsThreeDaysNewestFirst() {
        let day1 = DailyLog(date: "2026-05-01", items: [snippet("oldest")])
        let day2 = DailyLog(date: "2026-05-02", items: [snippet("middle")])
        let day3 = DailyLog(date: "2026-05-03", items: [snippet("newest")])
        let result = BrowseViewModel.groupSections(logs: [day1, day2, day3], now: .now)
        #expect(result.count == 3)
        #expect(result[0].snippets.first?.content == "newest")
        #expect(result[1].snippets.first?.content == "middle")
        #expect(result[2].snippets.first?.content == "oldest")
    }

    @Test func groupSectionsTwoDaysAgoIsFormattedNotYesterday() {
        let now = date(fromString: "2026-05-04")
        let log = DailyLog(date: "2026-05-02", items: [snippet("x")])
        let result = BrowseViewModel.groupSections(logs: [log], now: now)
        #expect(result[0].header == "May 2")
        #expect(result[0].header != "Yesterday")
    }

    // MARK: - DST-safe day boundary

    @Test func groupSectionsTodayHeaderOnDSTSpringForwardDay() {
        // 2026-03-08: US DST spring-forward — day is 23 hours long in affected timezones.
        let now = date(fromString: "2026-03-08")
        let log = DailyLog(date: "2026-03-08", items: [snippet("x")])
        let result = BrowseViewModel.groupSections(logs: [log], now: now)
        #expect(result[0].header == "Today")
    }

    @Test func groupSectionsYesterdayHeaderOnDSTSpringForwardDay() {
        // 2026-03-08: US DST spring-forward — calendar.date(byAdding: .day, value: -1)
        // must still yield 2026-03-07 even though the day is only 23 hours long.
        let now = date(fromString: "2026-03-08")
        let log = DailyLog(date: "2026-03-07", items: [snippet("x")])
        let result = BrowseViewModel.groupSections(logs: [log], now: now)
        #expect(result[0].header == "Yesterday")
    }

    @Test func groupSectionsTodayHeaderOnDSTFallBackDay() {
        // 2025-11-02: US DST fall-back — day is 25 hours long in affected timezones.
        let now = date(fromString: "2025-11-02")
        let log = DailyLog(date: "2025-11-02", items: [snippet("x")])
        let result = BrowseViewModel.groupSections(logs: [log], now: now)
        #expect(result[0].header == "Today")
    }

    @Test func groupSectionsYesterdayHeaderOnDSTFallBackDay() {
        // 2025-11-02: US DST fall-back — calendar.date(byAdding: .day, value: -1)
        // must still yield 2025-11-01 even though the day is 25 hours long.
        let now = date(fromString: "2025-11-02")
        let log = DailyLog(date: "2025-11-01", items: [snippet("x")])
        let result = BrowseViewModel.groupSections(logs: [log], now: now)
        #expect(result[0].header == "Yesterday")
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
