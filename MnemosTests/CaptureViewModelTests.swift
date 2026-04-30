import Testing
import Foundation
@testable import Mnemos

@MainActor
struct CaptureViewModelTests {

    @Test func initialStateIsEmpty() {
        let vm = CaptureViewModel()
        #expect(vm.content.isEmpty)
        #expect(vm.tagInput.isEmpty)
        #expect(vm.showConfirmation == false)
    }

    @Test func canSaveIsFalseWhenContentIsEmpty() {
        let vm = CaptureViewModel()
        #expect(vm.canSave == false)
    }

    @Test func canSaveIsFalseForWhitespaceOnly() {
        let vm = CaptureViewModel()
        vm.content = "   "
        #expect(vm.canSave == false)
    }

    @Test func canSaveIsTrueWithContent() {
        let vm = CaptureViewModel()
        vm.content = "Use @MainActor on stores"
        #expect(vm.canSave == true)
    }

    @Test func parsedTagsFromCommaSeparated() {
        let vm = CaptureViewModel()
        vm.tagInput = "swift, concurrency, actors"
        #expect(vm.parsedTags == ["swift", "concurrency", "actors"])
    }

    @Test func parsedTagsTrimsWhitespace() {
        let vm = CaptureViewModel()
        vm.tagInput = "  swift  ,  ui  "
        #expect(vm.parsedTags == ["swift", "ui"])
    }

    @Test func parsedTagsFiltersEmptySegments() {
        let vm = CaptureViewModel()
        vm.tagInput = ",swift,,ui,"
        #expect(vm.parsedTags == ["swift", "ui"])
    }

    @Test func parsedTagsEmptyWhenInputEmpty() {
        let vm = CaptureViewModel()
        #expect(vm.parsedTags.isEmpty)
    }
}
