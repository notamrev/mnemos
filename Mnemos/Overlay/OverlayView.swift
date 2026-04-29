import SwiftUI

struct OverlayView: View {
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

                Spacer()

                Text("Capture coming soon")
                    .foregroundStyle(.tertiary)

                Spacer()
            }
        }
        .ignoresSafeArea()
        .onExitCommand {
            (NSApp.delegate as? AppDelegate)?.toggleOverlay()
        }
    }
}

#Preview {
    OverlayView()
        .frame(width: 560, height: 320)
}
