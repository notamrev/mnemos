import SwiftUI

struct OverlayView: View {
    @Bindable var overlay: OverlayViewModel
    @State private var captureVM = CaptureViewModel()
    @State private var browseVM = BrowseViewModel()
    @FocusState private var contentFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(radius: 24)

            VStack(spacing: 0) {
                Picker("", selection: $overlay.mode) {
                    Text("Capture").tag(OverlayMode.capture)
                    Text("Browse").tag(OverlayMode.browse)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

                switch overlay.mode {
                case .capture:
                    captureBody
                case .browse:
                    BrowseView(vm: browseVM)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { contentFocused = (overlay.mode == .capture) }
        .onChange(of: overlay.showToken) { _, _ in contentFocused = true }
        .onChange(of: overlay.mode) { _, newMode in
            contentFocused = (newMode == .capture)
            if newMode == .browse { browseVM.load(from: .shared) }
        }
        .onExitCommand {
            (NSApp.delegate as? AppDelegate)?.toggleOverlay()
        }
        .background(
            Button("") { overlay.toggleMode() }
                .keyboardShortcut("b", modifiers: .command)
                .opacity(0)
        )
        .onKeyPress(.return, phases: .down) { event in
            guard overlay.mode == .capture,
                  event.modifiers.contains(.command),
                  captureVM.canSave else { return .ignored }
            try? captureVM.save(into: .shared)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.8))
                (NSApp.delegate as? AppDelegate)?.toggleOverlay()
                captureVM.showConfirmation = false
            }
            return .handled
        }
    }

    private var captureBody: some View {
        VStack(spacing: 0) {
            TextEditor(text: $captureVM.content)
                .focused($contentFocused)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 20)
                .frame(minHeight: 140)

            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

            HStack {
                TextField("tags, comma separated", text: $captureVM.tagInput)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if captureVM.showConfirmation {
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


}

#Preview {
    OverlayView(overlay: OverlayViewModel())
        .frame(width: 560, height: 320)
}
