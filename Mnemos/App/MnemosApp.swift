import SwiftUI

@main
struct MnemosApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // MenuBarExtra drives the status item; overlay is managed by AppDelegate
        MenuBarExtra("Mnemos", systemImage: "brain") {
            MenuBarView()
        }
    }
}
