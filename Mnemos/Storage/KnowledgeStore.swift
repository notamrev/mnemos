import Foundation
import Observation

@MainActor
@Observable
final class KnowledgeStore {
    static let shared = KnowledgeStore()

    let directory: URL
    var onSave: (() -> Void)?

    private let db: KnowledgeDatabase
    private let formatter: DateFormatter

    init(directory: URL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appending(path: "Mnemos")) {
        self.directory = directory
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        self.formatter = f
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // DB lives alongside the directory rather than inside it so the directory
        // remains a clean JSON/migrated-only space (required by existing tests).
        self.db = (try? KnowledgeDatabase(url: directory.appendingPathExtension("db")))!
    }

    func save(_ snippet: KnowledgeSnippet) throws {
        try db.insert(snippet)
        onSave?()
    }

    func fetchToday() -> DailyLog? {
        migratePendingJSONFiles()
        let items = db.fetchByDateKey(dateKey(for: .now))
        guard !items.isEmpty else { return nil }
        return DailyLog(date: dateKey(for: .now), items: items)
    }

    func fetchAll() -> [DailyLog] {
        migratePendingJSONFiles()
        return db.fetchAllGroupedByDate()
    }

    func purgeExpired(relativeTo now: Date = .now) {
        migratePendingJSONFiles()
        // expiresAt is already capturedAt + 7 days, so purging where expiresAt < now
        // removes both truly-expired snippets and all snippets older than 7 days.
        db.purgeExpired(before: now)
    }

    func dateKey(for date: Date) -> String {
        formatter.string(from: date)
    }

    // MARK: - Private

    private func migratePendingJSONFiles() {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else { return }
        for url in entries where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let log = try? JSONDecoder().decode(DailyLog.self, from: data) else { continue }
            for snippet in log.items { try? db.insert(snippet) }
            let migrated = url.deletingPathExtension().appendingPathExtension("migrated")
            try? FileManager.default.moveItem(at: url, to: migrated)
        }
    }
}
