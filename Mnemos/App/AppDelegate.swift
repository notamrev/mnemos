import AppKit
import ApplicationServices
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayWindowController: OverlayWindowController?
    private let hotKeyManager = HotKeyManager()
    var knowledgeStore: KnowledgeStore = .shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        knowledgeStore.purgeExpired()
        knowledgeStore.onSave = { SkillsCompiler.shared.scheduleCompile() }
        CaptureServer.shared.start()
        overlayWindowController = OverlayWindowController()
        hotKeyManager.onHotKey = { [weak self] in
            Task { @MainActor in self?.toggleOverlay() }
        }
        requestAccessibilityIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.unregister()
        CaptureServer.shared.stop()
    }

    // MARK: - Accessibility

    private func requestAccessibilityIfNeeded() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            hotKeyManager.register()
        } else {
            Task { @MainActor [weak self] in
                while !AXIsProcessTrusted() {
                    try? await Task.sleep(for: .seconds(1))
                }
                self?.hotKeyManager.register()
            }
        }
    }

    func toggleOverlay() {
        overlayWindowController?.toggle()
    }
}
