import Foundation

@MainActor
final class SkillsCompiler {
    static let shared = SkillsCompiler()

    private let store: KnowledgeStore
    let outputURL: URL
    private var debounceTask: Task<Void, Never>?

    init(
        store: KnowledgeStore = .shared,
        outputURL: URL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Mnemos/skills.json")
    ) {
        self.store = store
        self.outputURL = outputURL
    }

    @discardableResult
    func compile() throws -> [String: [String]] {
        let snippets = store.fetchAll().flatMap { $0.items }
        var grouped: [String: [String]] = [:]
        for snippet in snippets {
            let tags = snippet.tags.isEmpty ? ["general"] : snippet.tags
            for tag in tags {
                grouped[tag, default: []].append(snippet.content)
            }
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(grouped)
        try data.write(to: outputURL, options: .atomic)
        return grouped
    }

    func scheduleCompile() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            try? self?.compile()
        }
    }
}
