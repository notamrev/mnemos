import Testing
import SwiftUI
@testable import Mnemos

// SnippetRow and TagPill are pure view types with no extractable logic.
// These tests verify the API contract (types exist, initialise without crash).
// Behavioural coverage (layout, wrapping, pill rendering) is manual — see #37.

struct SnippetRowTests {

    @Test func tagPillInitialisesWithLabel() {
        let _ = TagPill(label: "swift")
    }

    @Test func snippetRowInitialisesWithEmptyTags() {
        let snippet = KnowledgeSnippet(content: "Use @MainActor", tags: [])
        let _ = SnippetRow(snippet: snippet, relativeTime: "Just now")
    }

    @Test func snippetRowInitialisesWithTags() {
        let snippet = KnowledgeSnippet(content: "Use @MainActor", tags: ["swift", "concurrency"])
        let _ = SnippetRow(snippet: snippet, relativeTime: "2 hours ago")
    }
}
