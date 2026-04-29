import Foundation

struct KnowledgeSnippet: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    let tags: [String]
    let capturedAt: Date
    let expiresAt: Date

    init(content: String, tags: [String], capturedAt: Date = .now) {
        self.id = UUID()
        self.content = content
        self.tags = tags
        self.capturedAt = capturedAt
        self.expiresAt = capturedAt.addingTimeInterval(7 * 24 * 60 * 60)
    }
}
