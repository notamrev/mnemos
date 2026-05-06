import Testing
import SwiftUI
@testable import Mnemos

// BrowseView empty state is pure view branching — no extractable logic.
// These tests verify the API contract used to drive that branching.

struct EmptyStateTests {

    @Test @MainActor func noSectionsIndicatesEmptyBrain() {
        let vm = BrowseViewModel()
        // vm.sections is empty by default — represents "no snippets in 7-day window"
        #expect(vm.sections.isEmpty)
    }

    @Test func filteredAndSearchedYieldEmptyWhenNothingMatches() {
        let snippet = KnowledgeSnippet(content: "Use @MainActor", tags: ["swift"])
        let sections = [BrowseSection(header: "Today", snippets: [snippet])]

        let afterTag = BrowseViewModel.filtered(sections: sections, tag: "design")
        #expect(afterTag.isEmpty)

        let afterSearch = BrowseViewModel.searched(sections: sections, query: "flowlayout")
        #expect(afterSearch.isEmpty)
    }

    @Test func nonEmptySectionsWithMatchingFilterIsNotEmpty() {
        let snippet = KnowledgeSnippet(content: "Use @MainActor", tags: ["swift"])
        let sections = [BrowseSection(header: "Today", snippets: [snippet])]

        let result = BrowseViewModel.searched(
            sections: BrowseViewModel.filtered(sections: sections, tag: "swift"),
            query: "mainactor"
        )
        #expect(!result.isEmpty)
    }
}
