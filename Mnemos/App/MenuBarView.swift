import SwiftUI

struct MenuBarView: View {
    var body: some View {
        Button("Open Mnemos") {
            (NSApp.delegate as? AppDelegate)?.toggleOverlay()
        }
        .keyboardShortcut("o")

        Button("Export Skills") {
            try? SkillsCompiler.shared.compile()
        }
        .keyboardShortcut("e")

        Divider()

        Button("Quit") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
