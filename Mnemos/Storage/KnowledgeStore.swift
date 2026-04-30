import Foundation
import Observation

@MainActor
@Observable
final class KnowledgeStore {
    static let shared = KnowledgeStore()

    let directory: URL

    init(directory: URL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appending(path: "Mnemos")) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func save(_ snippet: KnowledgeSnippet) throws {
        let key = dateKey(for: snippet.capturedAt)
        let url = directory.appending(path: "\(key).json")
        var log: DailyLog
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

    private func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }
}
