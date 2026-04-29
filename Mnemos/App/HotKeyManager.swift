import AppKit
import CoreGraphics

final class HotKeyManager: @unchecked Sendable {
    var onHotKey: (@Sendable () -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func register() {
        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.tapDisabledByTimeout.rawValue) |
            (1 << CGEventType.tapDisabledByUserInput.rawValue)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: selfPtr
        ) else {
            print("[Mnemos] CGEventTap failed — Accessibility permission may not be granted to this binary")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        print("[Mnemos] Global hotkey registered (⌘⇧M)")
    }

    func reEnable() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
            print("[Mnemos] Event tap re-enabled")
        }
    }

    func unregister() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
}

// Top-level C-compatible callback — cannot capture state, uses userInfo pointer instead.
private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    // System disabled our tap — re-enable it
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let ptr = userInfo {
            let manager = Unmanaged<HotKeyManager>.fromOpaque(ptr).takeUnretainedValue()
            manager.reEnable()
        }
        return Unmanaged.passRetained(event)
    }

    guard type == .keyDown else { return Unmanaged.passRetained(event) }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl])

    guard keyCode == 46, flags == [.maskCommand, .maskShift] else { // ⌘⇧M
        return Unmanaged.passRetained(event)
    }

    if let ptr = userInfo {
        let manager = Unmanaged<HotKeyManager>.fromOpaque(ptr).takeUnretainedValue()
        DispatchQueue.main.async { manager.onHotKey?() }
    }

    return nil // consume the event so no beep
}
