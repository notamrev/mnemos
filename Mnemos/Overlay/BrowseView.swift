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

private struct SnippetRow: View {
    let snippet: KnowledgeSnippet
    let relativeTime: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snippet.content)
                .font(.body)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(relativeTime)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
