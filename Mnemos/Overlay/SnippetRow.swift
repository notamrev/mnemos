import SwiftUI

struct SnippetRow: View {
    let snippet: KnowledgeSnippet
    let relativeTime: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snippet.content)
                .font(.body)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !snippet.tags.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(snippet.tags, id: \.self) { tag in
                        TagPill(label: tag)
                    }
                }
            }

            Text(relativeTime)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
