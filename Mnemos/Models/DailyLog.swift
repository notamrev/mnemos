import Foundation

struct DailyLog: Codable {
    let date: String  // YYYY-MM-DD
    var items: [KnowledgeSnippet]
}
