import SwiftUI

struct MenuBarView: View {
    var body: some View {
        Button("Open Mnemos") {
            (NSApp.delegate as? AppDelegate)?.toggleOverlay()
        }
        .keyboardShortcut("o")

        Divider()

        Button("Quit") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
