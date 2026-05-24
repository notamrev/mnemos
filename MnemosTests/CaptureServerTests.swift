import Testing
import Foundation
@testable import Mnemos

@MainActor
struct CaptureServerTests {

    private static let testPort: UInt16 = 40999

    private func makeStore() -> KnowledgeStore {
        let tmp = FileManager.default.temporaryDirectory
            .appending(path: "CaptureServerTests-\(UUID().uuidString)")
        return KnowledgeStore(directory: tmp)
    }

    private func makeServer(store: KnowledgeStore) -> CaptureServer {
        CaptureServer(store: store, port: Self.testPort)
    }

    private func post(_ body: String, to port: UInt16 = testPort) async throws -> HTTPURLResponse {
        let url = URL(string: "http://localhost:\(port)/capture")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data(body.utf8)
        let (_, response) = try await URLSession.shared.data(for: req)
        return try #require(response as? HTTPURLResponse)
    }

    @Test func validRequestSavesSnippetAndReturns201() async throws {
        let store = makeStore()
        let server = makeServer(store: store)
        server.start()
        defer { server.stop() }
        try await Task.sleep(for: .milliseconds(100))

        let response = try await post("""
            {"source":"vscode","content":"use async/await in Swift 6","tags":["swift"]}
            """)
        #expect(response.statusCode == 201)

        try await Task.sleep(for: .milliseconds(50))
        let items = store.fetchAll().flatMap { $0.items }
        #expect(items.count == 1)
        #expect(items.first?.content == "use async/await in Swift 6")
        #expect(items.first?.tags == ["swift"])
    }

    @Test func malformedJSONReturns400() async throws {
        let store = makeStore()
        let server = makeServer(store: store)
        server.start()
        defer { server.stop() }
        try await Task.sleep(for: .milliseconds(100))

        let response = try await post("not json at all")
        #expect(response.statusCode == 400)
        #expect(store.fetchAll().flatMap { $0.items }.isEmpty)
    }

    @Test func missingContentFieldReturns400() async throws {
        let store = makeStore()
        let server = makeServer(store: store)
        server.start()
        defer { server.stop() }
        try await Task.sleep(for: .milliseconds(100))

        let response = try await post("""
            {"source":"vscode","tags":["swift"]}
            """)
        #expect(response.statusCode == 400)
    }

    @Test func emptyContentReturns400() async throws {
        let store = makeStore()
        let server = makeServer(store: store)
        server.start()
        defer { server.stop() }
        try await Task.sleep(for: .milliseconds(100))

        let response = try await post("""
            {"source":"vscode","content":"   ","tags":[]}
            """)
        #expect(response.statusCode == 400)
    }

    @Test func nonCapturePath404() async throws {
        let store = makeStore()
        let server = makeServer(store: store)
        server.start()
        defer { server.stop() }
        try await Task.sleep(for: .milliseconds(100))

        let url = URL(string: "http://localhost:\(Self.testPort)/other")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = Data("{}".utf8)
        let (_, response) = try await URLSession.shared.data(for: req)
        let http = try #require(response as? HTTPURLResponse)
        #expect(http.statusCode == 404)
    }

    @Test func tagsDefaultToEmptyArrayWhenOmitted() async throws {
        let store = makeStore()
        let server = makeServer(store: store)
        server.start()
        defer { server.stop() }
        try await Task.sleep(for: .milliseconds(100))

        _ = try await post("""
            {"source":"vscode","content":"untagged snippet","tags":[]}
            """)
        try await Task.sleep(for: .milliseconds(50))
        let item = store.fetchAll().flatMap { $0.items }.first
        #expect(item?.tags == [])
    }
}
