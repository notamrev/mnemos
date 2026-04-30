import Foundation
import Observation

@MainActor
@Observable
final class KnowledgeStore {
    static let shared = KnowledgeStore()

    let directory: URL
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
        sweepTempFiles()
    }

    func save(_ snippet: KnowledgeSnippet) throws {
        let key = dateKey(for: snippet.capturedAt)
        let url = directory.appending(path: "\(key).json")
        let log: DailyLog
        if let existing = loadLog(at: url) {
            log = DailyLog(date: key, items: existing.items + [snippet])
        } else {
            log = DailyLog(date: key, items: [snippet])
        }
        try atomicWrite(log, to: url)
    }

    func fetchToday() -> DailyLog? {
        loadLog(at: directory.appending(path: "\(dateKey(for: .now)).json"))
    }

    func fetchAll() -> [DailyLog] {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else { return [] }
        return entries
            .filter { $0.pathExtension == "json" }
            .compactMap { loadLog(at: $0) }
            .sorted { $0.date < $1.date }
    }

    func purgeExpired(relativeTo now: Date = .now) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let cutoffKey = dateKey(for: cutoff)
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else { return }
        for url in entries where url.pathExtension == "json" {
            let stem = url.deletingPathExtension().lastPathComponent
            if stem < cutoffKey {
                try? FileManager.default.removeItem(at: url)
            } else if let log = loadLog(at: url) {
                let kept = log.items.filter { $0.expiresAt > now }
                if kept.count != log.items.count {
                    try? atomicWrite(DailyLog(date: log.date, items: kept), to: url)
                }
            }
        }
    }

    // MARK: - Private

    private func loadLog(at url: URL) -> DailyLog? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DailyLog.self, from: data)
    }

    private func atomicWrite(_ log: DailyLog, to url: URL) throws {
        let data = try JSONEncoder().encode(log)
        let tmp = directory.appending(path: UUID().uuidString + ".tmp")
        try data.write(to: tmp)
        _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
    }

    func dateKey(for date: Date) -> String {
        formatter.string(from: date)
    }

    private func sweepTempFiles() {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else { return }
        for url in entries where url.pathExtension == "tmp" {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
