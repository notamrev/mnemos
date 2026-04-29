# Class Diagram

> Last updated by PR #19 — KnowledgeSnippet and DailyLog models

```mermaid
classDiagram
    direction TB

    class KnowledgeSnippet {
        +UUID id
        +String content
        +[String] tags
        +Date capturedAt
        +Date expiresAt
        +init(content, tags, capturedAt)
    }

    class DailyLog {
        +String date
        +[KnowledgeSnippet] items
    }

    class HotKeyManager {
        <<@unchecked Sendable>>
        -CFMachPort? eventTap
        -CFRunLoopSource? runLoopSource
        +onHotKey: (@Sendable () -> Void)?
        +register()
        +unregister()
    }

    class OverlayWindowController {
        <<NSWindowController>>
        +showOverlay()
        +hideOverlay()
    }

    class AppDelegate {
        <<@MainActor>>
        -HotKeyManager hotKeyManager
        -OverlayWindowController? overlayController
        +applicationDidFinishLaunching()
        -requestAccessibilityIfNeeded()
        -waitForAccessibilityPermission()
    }

    DailyLog "1" *-- "0..*" KnowledgeSnippet : contains
    AppDelegate --> HotKeyManager : owns
    AppDelegate --> OverlayWindowController : owns
    HotKeyManager ..> AppDelegate : callback via onHotKey
```

## Notes
- `HotKeyManager` is `@unchecked Sendable` — access pattern is safe because `register()` is called once on the main thread and the CFRunLoop callback only invokes `onHotKey` which is assigned before registration.
- `OverlayWindowController` wraps an `NSPanel` with `.floating` level and `.nonactivatingPanel` style mask so the overlay appears above all windows without stealing focus.
- Hotkey is `⌘⇧M` via `CGEventTap` (requires Accessibility permission, not Input Monitoring).
