import Foundation
import SQLite3

@MainActor
final class KnowledgeDatabase {
    // nonisolated(unsafe): deinit can't access @MainActor storage; sqlite3_close is safe
    // at deallocation time since no other references can exist.
    nonisolated(unsafe) private var db: OpaquePointer?
    private let url: URL

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    init(url: URL) throws {
        self.url = url
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            throw DBError.open(String(cString: sqlite3_errmsg(db)))
        }
        try createSchema()
    }

    deinit {
        sqlite3_close(db)
    }

    func insert(_ snippet: KnowledgeSnippet) throws {
        let sql = """
            INSERT OR IGNORE INTO snippets (id, content, tags, source, captured_at, expires_at)
            VALUES (?, ?, ?, ?, ?, ?);
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepare(lastError)
        }
        defer { sqlite3_finalize(stmt) }

        let tagsJSON = (try? JSONEncoder().encode(snippet.tags)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        sqlite3_bind_text(stmt, 1, snippet.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, snippet.content, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, tagsJSON, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 4, snippet.source.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(stmt, 5, Int64(snippet.capturedAt.timeIntervalSince1970))
        sqlite3_bind_int64(stmt, 6, Int64(snippet.expiresAt.timeIntervalSince1970))

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DBError.step(lastError)
        }
    }

    func fetchByDateKey(_ key: String) -> [KnowledgeSnippet] {
        let sql = """
            SELECT id, content, tags, source, captured_at, expires_at
            FROM snippets
            WHERE strftime('%Y-%m-%d', captured_at, 'unixepoch') = ?;
            """
        return query(sql, bindings: [key])
    }

    func fetchAllGroupedByDate() -> [DailyLog] {
        let sql = """
            SELECT id, content, tags, source, captured_at, expires_at
            FROM snippets
            ORDER BY captured_at ASC;
            """
        let snippets = query(sql, bindings: [])
        var groups: [String: [KnowledgeSnippet]] = [:]
        for snippet in snippets {
            let key = Self.dateFormatter.string(from: snippet.capturedAt)
            groups[key, default: []].append(snippet)
        }
        return groups.keys.sorted().map { DailyLog(date: $0, items: groups[$0]!) }
    }

    func fetchByTag(_ tag: String) -> [KnowledgeSnippet] {
        // json_each lets us match exact tag values inside the stored JSON array.
        let sql = """
            SELECT s.id, s.content, s.tags, s.source, s.captured_at, s.expires_at
            FROM snippets s, json_each(s.tags) je
            WHERE je.value = ?;
            """
        return query(sql, bindings: [tag])
    }

    func purgeExpired(before date: Date) {
        let sql = "DELETE FROM snippets WHERE expires_at < ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int64(stmt, 1, Int64(date.timeIntervalSince1970))
        sqlite3_step(stmt)
    }

    func deleteAll() {
        sqlite3_exec(db, "DELETE FROM snippets;", nil, nil, nil)
    }

    func search(query queryString: String, limit: Int = 20) -> [KnowledgeSnippet] {
        let sql = """
            SELECT s.id, s.content, s.tags, s.source, s.captured_at, s.expires_at
            FROM snippets s
            JOIN snippets_fts f ON s.rowid = f.rowid
            WHERE snippets_fts MATCH ?
            ORDER BY rank
            LIMIT ?;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, queryString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(stmt, 2, Int64(limit))
        return collectRows(stmt)
    }

    func allTags() -> [String] {
        let sql = "SELECT tags FROM snippets;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        var result: Set<String> = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let raw = sqlite3_column_text(stmt, 0),
               let data = String(cString: raw).data(using: .utf8),
               let tags = try? JSONDecoder().decode([String].self, from: data) {
                tags.forEach { result.insert($0) }
            }
        }
        return result.sorted()
    }

    // MARK: - Private

    private func createSchema() throws {
        let ddl = """
            CREATE TABLE IF NOT EXISTS snippets (
                id          TEXT PRIMARY KEY,
                content     TEXT NOT NULL,
                tags        TEXT NOT NULL,
                source      TEXT NOT NULL DEFAULT 'manual',
                captured_at INTEGER NOT NULL,
                expires_at  INTEGER NOT NULL,
                metadata    TEXT
            );

            CREATE VIRTUAL TABLE IF NOT EXISTS snippets_fts
                USING fts5(content, tags, content='snippets', content_rowid='rowid');

            CREATE TRIGGER IF NOT EXISTS snippets_ai AFTER INSERT ON snippets BEGIN
                INSERT INTO snippets_fts(rowid, content, tags)
                VALUES (new.rowid, new.content, new.tags);
            END;

            CREATE TRIGGER IF NOT EXISTS snippets_ad AFTER DELETE ON snippets BEGIN
                INSERT INTO snippets_fts(snippets_fts, rowid, content, tags)
                VALUES ('delete', old.rowid, old.content, old.tags);
            END;
            """
        var err: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, ddl, nil, nil, &err) == SQLITE_OK else {
            let msg = err.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(err)
            throw DBError.exec(msg)
        }
    }

    private func query(_ sql: String, bindings: [String]) -> [KnowledgeSnippet] {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        for (i, value) in bindings.enumerated() {
            sqlite3_bind_text(stmt, Int32(i + 1), value, -1, SQLITE_TRANSIENT)
        }
        return collectRows(stmt)
    }

    private func collectRows(_ stmt: OpaquePointer?) -> [KnowledgeSnippet] {
        var results: [KnowledgeSnippet] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard
                let idRaw = sqlite3_column_text(stmt, 0),
                let id = UUID(uuidString: String(cString: idRaw)),
                let contentRaw = sqlite3_column_text(stmt, 1),
                let tagsRaw = sqlite3_column_text(stmt, 2)
            else { continue }

            let content = String(cString: contentRaw)
            let tagsJSON = String(cString: tagsRaw)
            let tags = (tagsJSON.data(using: .utf8)).flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? []
            let sourceRaw = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? "manual"
            let source = SnippetSource(rawValue: sourceRaw) ?? .manual
            let capturedAt = Date(timeIntervalSince1970: Double(sqlite3_column_int64(stmt, 4)))
            let expiresAt = Date(timeIntervalSince1970: Double(sqlite3_column_int64(stmt, 5)))

            results.append(KnowledgeSnippet(
                id: id, content: content, tags: tags, source: source,
                capturedAt: capturedAt, expiresAt: expiresAt
            ))
        }
        return results
    }

    private var lastError: String {
        db.map { String(cString: sqlite3_errmsg($0)) } ?? "no db"
    }
}

enum DBError: Error {
    case open(String)
    case prepare(String)
    case step(String)
    case exec(String)
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
