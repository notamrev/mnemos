import SwiftUI

struct BrowseView: View {
    let vm: BrowseViewModel

    var body: some View {
        List {
            ForEach(vm.sections, id: \.header) { section in
                Section(section.header) {
                    ForEach(section.snippets) { snippet in
                        SnippetRow(snippet: snippet, relativeTime: BrowseViewModel.relativeTime(for: snippet, now: .now))
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

