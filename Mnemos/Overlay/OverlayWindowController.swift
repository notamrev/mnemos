import AppKit
import SwiftUI

final class OverlayWindowController: NSWindowController {
    convenience init() {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        let contentView = NSHostingView(rootView: OverlayView())
        contentView.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = contentView

        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalToConstant: 560),
            contentView.heightAnchor.constraint(equalToConstant: 320),
        ])
        panel.setContentSize(CGSize(width: 560, height: 320))

        self.init(window: panel)
    }

    func toggle() {
        guard let window else { return }
        if window.isVisible {
            close()
        } else {
            centerOnActiveScreen()
            showWindow(nil)
            window.makeFirstResponder(window.contentView)
        }
    }

    private func centerOnActiveScreen() {
        guard let window,
              let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
               ?? NSScreen.main
        else { return }
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let origin = CGPoint(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.midY - windowSize.height / 2 + screenFrame.height * 0.1
        )
        window.setFrameOrigin(origin)
    }
}
