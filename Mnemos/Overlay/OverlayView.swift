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

                HStack {
                    TextField("tags, comma separated", text: $vm.tagInput)
                        .textFieldStyle(.plain)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    if vm.showConfirmation {
                        Text("Saved ✓")
                            .font(.callout)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea()
        .onAppear { contentFocused = true }
        .onExitCommand {
            (NSApp.delegate as? AppDelegate)?.toggleOverlay()
        }
        .keyboardShortcut(.return, modifiers: .command)
        .onKeyPress(.return, phases: .down) { event in
            guard event.modifiers.contains(.command), vm.canSave else { return .ignored }
            try? vm.save(into: .shared)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.8))
                (NSApp.delegate as? AppDelegate)?.toggleOverlay()
                vm.showConfirmation = false
            }
            return .handled
        }
    }
}

#Preview {
    OverlayView()
        .frame(width: 560, height: 320)
}
