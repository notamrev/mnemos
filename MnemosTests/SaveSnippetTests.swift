import Testing
import Foundation
@testable import Mnemos

@MainActor
struct SaveSnippetTests {

    private func makeStore() -> KnowledgeStore {
        let tmp = FileManager.default.temporaryDirectory
            .appending(path: "MnemosSave-\(UUID().uuidString)")
        return KnowledgeStore(directory: tmp)
    }

    @Test func saveStoresSnippetInKnowledgeStore() throws {
        let store = makeStore()
        let vm = CaptureViewModel()
        vm.content = "Always use @MainActor for stores"
        vm.tagInput = "swift"
        try vm.save(into: store)
        let log = try #require(store.fetchToday())
        #expect(log.items.count == 1)
        #expect(log.items[0].content == "Always use @MainActor for stores")
        #expect(log.items[0].tags == ["swift"])
    }

    @Test func saveSetsConfirmationFlag() throws {
        let store = makeStore()
        let vm = CaptureViewModel()
        vm.content = "test content"
        try vm.save(into: store)
        #expect(vm.showConfirmation == true)
    }

    @Test func saveClearsContentAndTagInput() throws {
        let store = makeStore()
        let vm = CaptureViewModel()
        vm.content = "some content"
        vm.tagInput = "tag1, tag2"
        try vm.save(into: store)
        #expect(vm.content.isEmpty)
        #expect(vm.tagInput.isEmpty)
    }

    @Test func saveThrowsDoNothingWhenCannotSave() throws {
        let store = makeStore()
        let vm = CaptureViewModel()
        vm.content = ""
        try vm.save(into: store)
        #expect(store.fetchToday() == nil)
        #expect(vm.showConfirmation == false)
    }

    @Test func saveTrimmsLeadingTrailingWhitespaceFromContent() throws {
        let store = makeStore()
        let vm = CaptureViewModel()
        vm.content = "  trimmed content  "
        try vm.save(into: store)
        let log = try #require(store.fetchToday())
        #expect(log.items[0].content == "trimmed content")
    }
}
