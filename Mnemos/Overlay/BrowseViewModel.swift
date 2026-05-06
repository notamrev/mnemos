import Foundation
import Observation

struct BrowseSection {
    let header: String
    let snippets: [KnowledgeSnippet]
}

@MainActor
@Observable
final class BrowseViewModel {
    private(set) var sections: [BrowseSection] = []

    func load(from store: KnowledgeStore) {
        sections = Self.groupSections(logs: store.fetchAll(), now: .now)
    }

    nonisolated static func filtered(sections: [BrowseSection], tag: String?) -> [BrowseSection] {
        guard let tag else { return sections }
        return sections.compactMap { section in
            let matching = section.snippets.filter { $0.tags.contains(tag) }
            return matching.isEmpty ? nil : BrowseSection(header: section.header, snippets: matching)
        }
    }

    nonisolated static func groupSections(logs: [DailyLog], now: Date) -> [BrowseSection] {
        let calendar = Calendar.current
        let todayKey = dayKey(for: now)
        let yesterdayKey = dayKey(for: calendar.date(byAdding: .day, value: -1, to: now) ?? now)

        return logs
            .filter { !$0.items.isEmpty }
            .sorted { $0.date > $1.date }
            .map { log in
                let header: String
                if log.date == todayKey {
                    header = "Today"
                } else if log.date == yesterdayKey {
                    header = "Yesterday"
                } else {
                    header = formattedDate(from: log.date)
                }
                let sorted = log.items.sorted { $0.capturedAt > $1.capturedAt }
                return BrowseSection(header: header, snippets: sorted)
            }
    }

    nonisolated static func relativeTime(for snippet: KnowledgeSnippet, now: Date) -> String {
        let elapsed = now.timeIntervalSince(snippet.capturedAt)
        switch elapsed {
        case ..<60:
            return "Just now"
        case ..<3600:
            let minutes = Int(elapsed / 60)
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        default:
            let hours = Int(elapsed / 3600)
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }
    }

    private nonisolated static func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }

    private nonisolated static func formattedDate(from key: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        guard let date = f.date(from: key) else { return key }
        let out = DateFormatter()
        out.dateFormat = "MMM d"
        out.locale = Locale(identifier: "en_US_POSIX")
        return out.string(from: date)
    }
}
