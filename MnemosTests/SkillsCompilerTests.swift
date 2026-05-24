import Testing
import Foundation
@testable import Mnemos

@MainActor
struct SkillsCompilerTests {

    private func makeStore() -> KnowledgeStore {
        let tmp = FileManager.default.temporaryDirectory
            .appending(path: "SkillsCompilerTests-\(UUID().uuidString)")
        return KnowledgeStore(directory: tmp)
    }

    private func makeCompiler(store: KnowledgeStore) -> (SkillsCompiler, URL) {
        let outputURL = FileManager.default.temporaryDirectory
            .appending(path: "skills-\(UUID().uuidString).json")
        return (SkillsCompiler(store: store, outputURL: outputURL), outputURL)
    }

    @Test func snippetsGroupedByTag() throws {
        let store = makeStore()
        let (compiler, _) = makeCompiler(store: store)
        try store.save(KnowledgeSnippet(content: "use async/await", tags: ["swift"]))
        try store.save(KnowledgeSnippet(content: "tokens expire after 5m", tags: ["auth"]))
        let result = try compiler.compile()
        #expect(result["swift"] == ["use async/await"])
        #expect(result["auth"] == ["tokens expire after 5m"])
    }

    @Test func untaggedSnippetsGoToGeneral() throws {
        let store = makeStore()
        let (compiler, _) = makeCompiler(store: store)
        try store.save(KnowledgeSnippet(content: "general tip", tags: []))
        let result = try compiler.compile()
        #expect(result["general"] == ["general tip"])
    }

    @Test func multiTagSnippetAppearsUnderEachTag() throws {
        let store = makeStore()
        let (compiler, _) = makeCompiler(store: store)
        try store.save(KnowledgeSnippet(content: "structured concurrency", tags: ["swift", "concurrency"]))
        let result = try compiler.compile()
        #expect(result["swift"]?.contains("structured concurrency") == true)
        #expect(result["concurrency"]?.contains("structured concurrency") == true)
    }

    @Test func multipleSnippetsSameTagAreAggregated() throws {
        let store = makeStore()
        let (compiler, _) = makeCompiler(store: store)
        try store.save(KnowledgeSnippet(content: "first", tags: ["swift"]))
        try store.save(KnowledgeSnippet(content: "second", tags: ["swift"]))
        let result = try compiler.compile()
        #expect(result["swift"]?.count == 2)
        #expect(result["swift"]?.contains("first") == true)
        #expect(result["swift"]?.contains("second") == true)
    }

    @Test func emptyStoreWritesEmptyObject() throws {
        let store = makeStore()
        let (compiler, outputURL) = makeCompiler(store: store)
        let result = try compiler.compile()
        #expect(result.isEmpty)
        #expect(FileManager.default.fileExists(atPath: outputURL.path()))
    }

    @Test func outputIsValidJSONSchema() throws {
        let store = makeStore()
        let (compiler, outputURL) = makeCompiler(store: store)
        try store.save(KnowledgeSnippet(content: "test snippet", tags: ["tag"]))
        try compiler.compile()
        let data = try Data(contentsOf: outputURL)
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: [String]]
        #expect(parsed != nil)
        #expect(parsed?["tag"] == ["test snippet"])
    }

    @Test func outputFileIsWritten() throws {
        let store = makeStore()
        let (compiler, outputURL) = makeCompiler(store: store)
        try store.save(KnowledgeSnippet(content: "anything", tags: ["x"]))
        try compiler.compile()
        #expect(FileManager.default.fileExists(atPath: outputURL.path()))
    }
}
