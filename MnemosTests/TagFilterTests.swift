import Testing
import SwiftUI
@testable import Mnemos

struct TagFilterTests {

    // MARK: - BrowseViewModel.filtered(sections:tag:) logic

    @Test func filteredWithNilTagReturnsAllSections() {
        let s1 = KnowledgeSnippet(content: "Alpha", tags: ["swift"])
        let s2 = KnowledgeSnippet(content: "Beta", tags: ["design"])
        let sections = [BrowseSection(header: "Today", snippets: [s1, s2])]

        let result = BrowseViewModel.filtered(sections: sections, tag: nil)

        #expect(result.count == 1)
        #expect(result[0].snippets.count == 2)
    }

    @Test func filteredKeepsOnlySnippetsMatchingTag() {
        let match = KnowledgeSnippet(content: "Alpha", tags: ["swift", "ios"])
        let noMatch = KnowledgeSnippet(content: "Beta", tags: ["design"])
        let sections = [BrowseSection(header: "Today", snippets: [match, noMatch])]

        let result = BrowseViewModel.filtered(sections: sections, tag: "swift")

        #expect(result.count == 1)
        #expect(result[0].snippets.count == 1)
        #expect(result[0].snippets[0].content == "Alpha")
    }

    @Test func filteredDropsSectionsWhereNoSnippetsMatch() {
        let s1 = KnowledgeSnippet(content: "Alpha", tags: ["swift"])
        let s2 = KnowledgeSnippet(content: "Beta", tags: ["design"])
        let sections = [
            BrowseSection(header: "Today", snippets: [s1]),
            BrowseSection(header: "Yesterday", snippets: [s2])
        ]

        let result = BrowseViewModel.filtered(sections: sections, tag: "swift")

        #expect(result.count == 1)
        #expect(result[0].header == "Today")
    }

    @Test func filteredPreservesSectionHeaderForMatchingSections() {
        let match = KnowledgeSnippet(content: "Alpha", tags: ["swift"])
        let sections = [BrowseSection(header: "May 1", snippets: [match])]

        let result = BrowseViewModel.filtered(sections: sections, tag: "swift")

        #expect(result[0].header == "May 1")
    }

    @Test func filteredReturnsEmptyWhenNoSectionsMatchTag() {
        let s1 = KnowledgeSnippet(content: "Alpha", tags: ["design"])
        let sections = [BrowseSection(header: "Today", snippets: [s1])]

        let result = BrowseViewModel.filtered(sections: sections, tag: "swift")

        #expect(result.isEmpty)
    }

    // MARK: - Updated API contracts

    @Test func tagPillInitialisesWithSelectedState() {
        let _ = TagPill(label: "swift", isSelected: true, onTap: nil)
    }

    @Test func snippetRowInitialisesWithTagTapHandler() {
        let snippet = KnowledgeSnippet(content: "Use @MainActor", tags: ["swift"])
        let _ = SnippetRow(snippet: snippet, relativeTime: "Just now", onTagTap: { _ in })
    }
}
