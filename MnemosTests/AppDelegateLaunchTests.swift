import Testing
import Foundation
import AppKit
@testable import Mnemos

@MainActor
struct AppDelegateLaunchTests {

    @Test func applicationDidFinishLaunchingPurgesExpiredSnippets() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appending(path: "MnemosLaunch-\(UUID().uuidString)")
        let store = KnowledgeStore(directory: tmp)
        let eightDaysAgo = Date.now.addingTimeInterval(-8 * 86400)
        try store.save(KnowledgeSnippet(content: "stale", tags: [], capturedAt: eightDaysAgo))
        #expect(store.fetchAll().count == 1)

        let delegate = AppDelegate()
        delegate.knowledgeStore = store
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        #expect(store.fetchAll().isEmpty)
    }
}
