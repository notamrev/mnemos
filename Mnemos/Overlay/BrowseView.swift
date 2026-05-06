import SwiftUI

struct BrowseView: View {
    let vm: BrowseViewModel
    @State private var selectedTag: String?
    @State private var searchText: String = ""

    private var displayedSections: [BrowseSection] {
        let tagFiltered = BrowseViewModel.filtered(sections: vm.sections, tag: selectedTag)
        return BrowseViewModel.searched(sections: tagFiltered, query: searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search snippets…", text: $searchText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.5))

            if let tag = selectedTag {
                HStack {
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                    Button {
                        selectedTag = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }

            List {
                ForEach(displayedSections, id: \.header) { section in
                    Section(section.header) {
                        ForEach(section.snippets) { snippet in
                            SnippetRow(
                                snippet: snippet,
                                relativeTime: BrowseViewModel.relativeTime(for: snippet, now: .now),
                                onTagTap: { tapped in
                                    selectedTag = selectedTag == tapped ? nil : tapped
                                }
                            )
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}
