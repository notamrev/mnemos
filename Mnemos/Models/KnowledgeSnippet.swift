import Foundation

enum SnippetSource: String, Codable {
    case manual
    case vscode
}

struct KnowledgeSnippet: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    let tags: [String]
    let source: SnippetSource
    let capturedAt: Date
    let expiresAt: Date

    init(content: String, tags: [String], capturedAt: Date = .now, source: SnippetSource = .manual) {
        // Truncate to whole seconds so round-trips through integer-second storage are lossless.
        let ts = Date(timeIntervalSince1970: capturedAt.timeIntervalSince1970.rounded(.down))
        self.id = UUID()
        self.content = content
        self.tags = tags
        self.source = source
        self.capturedAt = ts
        self.expiresAt = ts.addingTimeInterval(7 * 24 * 60 * 60)
    }

    // Separate init prevents UUID regeneration when reconstructing rows from the DB.
    init(id: UUID, content: String, tags: [String], source: SnippetSource, capturedAt: Date, expiresAt: Date) {
        self.id = id
        self.content = content
        self.tags = tags
        self.source = source
        self.capturedAt = capturedAt
        self.expiresAt = expiresAt
    }

    // Decodes legacy JSON that may lack the `source` field.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        content = try c.decode(String.self, forKey: .content)
        tags = try c.decode([String].self, forKey: .tags)
        source = (try? c.decode(SnippetSource.self, forKey: .source)) ?? .manual
        capturedAt = try c.decode(Date.self, forKey: .capturedAt)
        expiresAt = try c.decode(Date.self, forKey: .expiresAt)
    }
}
