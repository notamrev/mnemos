import SwiftUI

struct OverlayView: View {
    @Bindable var overlay: OverlayViewModel
    @State private var vm = CaptureViewModel()
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
                    browseBody
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { contentFocused = (overlay.mode == .capture) }
        .onChange(of: overlay.mode) { _, newMode in
            contentFocused = (newMode == .capture)
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
                  vm.canSave else { return .ignored }
            try? vm.save(into: .shared)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.8))
                (NSApp.delegate as? AppDelegate)?.toggleOverlay()
                vm.showConfirmation = false
            }
            return .handled
        }
    }

    private var captureBody: some View {
        VStack(spacing: 0) {
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

    private var browseBody: some View {
        VStack {
            Spacer()
            Text("Browse coming soon")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 16)
    }
}

#Preview {
    OverlayView(overlay: OverlayViewModel())
        .frame(width: 560, height: 320)
}
