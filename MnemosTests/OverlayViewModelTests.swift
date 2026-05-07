import Testing
@testable import Mnemos

@MainActor
struct OverlayViewModelTests {

    @Test func initialModeIsCapture() {
        let vm = OverlayViewModel()
        #expect(vm.mode == .capture)
    }

    @Test func toggleModeSwitchesCaptureToBrowse() {
        let vm = OverlayViewModel()
        vm.toggleMode()
        #expect(vm.mode == .browse)
    }

    @Test func toggleModeSwitchesBrowseToCapture() {
        let vm = OverlayViewModel()
        vm.mode = .browse
        vm.toggleMode()
        #expect(vm.mode == .capture)
    }

    @Test func resetReturnsToCapture() {
        let vm = OverlayViewModel()
        vm.mode = .browse
        vm.reset()
        #expect(vm.mode == .capture)
    }

    @Test func resetFromCaptureIsIdempotent() {
        let vm = OverlayViewModel()
        vm.reset()
        #expect(vm.mode == .capture)
    }

    @Test func resetIncrementsShowToken() {
        let vm = OverlayViewModel()
        let before = vm.showToken
        vm.reset()
        #expect(vm.showToken == before + 1)
    }

    @Test func resetIncrementsShowTokenCumulatively() {
        let vm = OverlayViewModel()
        vm.reset()
        vm.reset()
        vm.reset()
        #expect(vm.showToken == 3)
    }
}
