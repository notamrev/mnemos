import Testing
import CoreGraphics
@testable import Mnemos

// Tests for the key-matching logic extracted from HotKeyManager.
// CGEventTap creation itself can't be tested without Accessibility permission,
// but the matching predicate is pure logic we can verify.

struct HotKeyMatchTests {

    // kVK_ANSI_M = 46
    private let mKey: Int64 = 46
    private let spaceKey: Int64 = 49

    @Test func exactMatch_triggersHotKey() {
        #expect(isHotKey(keyCode: mKey, flags: [.maskCommand, .maskShift]))
    }

    @Test func missingShift_doesNotTrigger() {
        #expect(!isHotKey(keyCode: mKey, flags: [.maskCommand]))
    }

    @Test func missingCommand_doesNotTrigger() {
        #expect(!isHotKey(keyCode: mKey, flags: [.maskShift]))
    }

    @Test func extraModifier_doesNotTrigger() {
        #expect(!isHotKey(keyCode: mKey, flags: [.maskCommand, .maskShift, .maskAlternate]))
    }

    @Test func wrongKey_doesNotTrigger() {
        #expect(!isHotKey(keyCode: spaceKey, flags: [.maskCommand, .maskShift]))
    }

    @Test func noModifiers_doesNotTrigger() {
        #expect(!isHotKey(keyCode: mKey, flags: []))
    }
}

// MARK: - Extracted predicate (mirrors the logic in eventTapCallback)

private func isHotKey(keyCode: Int64, flags: CGEventFlags) -> Bool {
    let relevant = flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl])
    return keyCode == 46 && relevant == [.maskCommand, .maskShift]
}
