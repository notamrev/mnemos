import Testing
import SwiftUI
@testable import Mnemos

struct SearchBarTests {

    // MARK: - BrowseViewModel.searched(sections:query:) logic

    @Test func searchedWithEmptyQueryReturnsAllSections() {
        let s1 = KnowledgeSnippet(content: "Use @MainActor for thread safety", tags: [])
        let sections = [BrowseSection(header: "Today", snippets: [s1])]

        let result = BrowseViewModel.searched(sections: sections, query: "")

        #expect(result.count == 1)
        #expect(result[0].snippets.count == 1)
    }

    @Test func searchedMatchesContentCaseInsensitive() {
        let match = KnowledgeSnippet(content: "Use @MainActor for thread safety", tags: [])
        let noMatch = KnowledgeSnippet(content: "FlowLayout wraps pills", tags: [])
        let sections = [BrowseSection(header: "Today", snippets: [match, noMatch])]

        let result = BrowseViewModel.searched(sections: sections, query: "mainactor")

        #expect(result[0].snippets.count == 1)
        #expect(result[0].snippets[0].content == "Use @MainActor for thread safety")
    }

    @Test func searchedIsCaseInsensitiveForMixedCase() {
        let snippet = KnowledgeSnippet(content: "Swift Concurrency with async/await", tags: [])
        let sections = [BrowseSection(header: "Today", snippets: [snippet])]

        let result = BrowseViewModel.searched(sections: sections, query: "SWIFT CONCURRENCY")

        #expect(result[0].snippets.count == 1)
    }

    @Test func searchedDropsSectionsWithNoMatchingSnippets() {
        let s1 = KnowledgeSnippet(content: "Use @MainActor", tags: [])
        let s2 = KnowledgeSnippet(content: "FlowLayout wraps pills", tags: [])
        let sections = [
            BrowseSection(header: "Today", snippets: [s1]),
            BrowseSection(header: "Yesterday", snippets: [s2])
        ]

        let result = BrowseViewModel.searched(sections: sections, query: "mainactor")

        #expect(result.count == 1)
        #expect(result[0].header == "Today")
    }

    @Test func searchedPreservesSectionHeaderWhenMatchFound() {
        let snippet = KnowledgeSnippet(content: "Use @MainActor", tags: [])
        let sections = [BrowseSection(header: "May 1", snippets: [snippet])]

        let result = BrowseViewModel.searched(sections: sections, query: "mainactor")

        #expect(result[0].header == "May 1")
    }

    @Test func searchedReturnsEmptyWhenNothingMatches() {
        let snippet = KnowledgeSnippet(content: "FlowLayout wraps pills", tags: [])
        let sections = [BrowseSection(header: "Today", snippets: [snippet])]

        let result = BrowseViewModel.searched(sections: sections, query: "mainactor")

        #expect(result.isEmpty)
    }

    // MARK: - Composition: search + tag filter both active

    @Test func searchAndTagFilterCompose() {
        let bothMatch = KnowledgeSnippet(content: "Use @MainActor", tags: ["swift"])
        let tagOnlyMatch = KnowledgeSnippet(content: "FlowLayout wraps pills", tags: ["swift"])
        let searchOnlyMatch = KnowledgeSnippet(content: "Use @MainActor without tags", tags: ["design"])
        let sections = [BrowseSection(header: "Today", snippets: [bothMatch, tagOnlyMatch, searchOnlyMatch])]

        let tagFiltered = BrowseViewModel.filtered(sections: sections, tag: "swift")
        let result = BrowseViewModel.searched(sections: tagFiltered, query: "mainactor")

        #expect(result[0].snippets.count == 1)
        #expect(result[0].snippets[0].content == "Use @MainActor")
    }
}
