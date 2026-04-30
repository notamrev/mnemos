import SwiftUI

struct OverlayView: View {
    @State private var vm = CaptureViewModel()
    @FocusState private var contentFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(radius: 24)

            VStack(spacing: 0) {
                Text("Mnemos")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                TextEditor(text: $vm.content)
                    .focused($contentFocused)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 140)

                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                TextField("tags, comma separated", text: $vm.tagInput)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea()
        .onAppear { contentFocused = true }
        .onExitCommand {
            (NSApp.delegate as? AppDelegate)?.toggleOverlay()
        }
    }
}

#Preview {
    OverlayView()
        .frame(width: 560, height: 320)
}
