import Foundation
import Observation

@MainActor
@Observable
final class CaptureViewModel {
    var content = ""
    var tagInput = ""
    var showConfirmation = false

    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var parsedTags: [String] {
        tagInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func save(into store: KnowledgeStore) throws {
        guard canSave else { return }
        let snippet = KnowledgeSnippet(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: parsedTags
        )
        try store.save(snippet)
        content = ""
        tagInput = ""
        showConfirmation = true
    }
}
