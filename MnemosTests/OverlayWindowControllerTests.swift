import Testing
import AppKit
@testable import Mnemos

@MainActor
struct OverlayWindowControllerTests {

    @Test func toggle_showsWindowWhenHidden() {
        let controller = OverlayWindowController()
        controller.window?.orderOut(nil) // ensure hidden

        controller.toggle()

        #expect(controller.window?.isVisible == true)
    }

    @Test func toggle_hidesWindowWhenVisible() {
        let controller = OverlayWindowController()
        controller.toggle() // show first
        controller.toggle() // then hide

        #expect(controller.window?.isVisible == false)
    }

    @Test func window_hasFloatingLevel() {
        let controller = OverlayWindowController()
        #expect(controller.window?.level == .floating)
    }

    @Test func window_hasExpectedSize() {
        let controller = OverlayWindowController()
        let size = controller.window?.frame.size
        #expect(size?.width == 560)
        #expect(size?.height == 320)
    }
}
