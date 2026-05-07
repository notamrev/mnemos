import Testing
import SwiftUI
@testable import Mnemos

struct EmptyStateTests {

    @Test @MainActor func noSectionsIndicatesEmptyBrain() {
        let vm = BrowseViewModel()
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

    @Test func nonEmptySectionsWithNoMatchYieldsEmptyDisplayed() {
        let snippet = KnowledgeSnippet(content: "Use @MainActor", tags: ["swift"])
        let sections = [BrowseSection(header: "Today", snippets: [snippet])]

        let displayed = BrowseViewModel.searched(
            sections: BrowseViewModel.filtered(sections: sections, tag: "design"),
            query: ""
        )
        #expect(!sections.isEmpty)
        #expect(displayed.isEmpty)
    }
}
