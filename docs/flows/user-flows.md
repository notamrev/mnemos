# User Flows

> Last updated by PR #6 — overlay shell (hotkey + NSPanel)

---

## Flow 1: Knowledge Capture (primary flow)

```mermaid
flowchart TD
    A([User presses ⌘⇧M]) --> B{Accessibility\npermission granted?}
    B -- No --> C[System prompt:\nRequest Accessibility access]
    C --> D[User opens System Settings\nand grants permission]
    D --> A
    B -- Yes --> E[Overlay panel slides in\ncentred on active screen]
    E --> F[User types knowledge snippet]
    F --> G[User adds tags\ne.g. #swift #architecture]
    G --> H{Submit or dismiss?}
    H -- "↵ Return" --> I[Append KnowledgeSnippet\nto today's DailyLog]
    I --> J[Overlay dismisses]
    H -- "⎋ Escape" --> J
    J --> K([Snippet stored,\nexpires in 7 days])
```

---

## Flow 2: App Launch

```mermaid
flowchart TD
    A([App launches]) --> B[AppDelegate.applicationDidFinishLaunching]
    B --> C{Accessibility\npermission?}
    C -- No --> D[Show permission prompt\nAXIsProcessTrustedWithOptions]
    D --> E[Poll every 1s via Task.sleep]
    E --> C
    C -- Yes --> F[Register CGEventTap\nfor ⌘⇧M]
    F --> G[MenuBarExtra icon appears]
    G --> H([App ready, runs in background])
```

---

## Flow 3: Snippet Expiry (rolling 7-day window)

```mermaid
flowchart TD
    A([App launches]) --> B[Load all DailyLog files\nfrom disk]
    B --> C{Any log file older\nthan 7 days?}
    C -- Yes --> D[Delete expired file\nand its snippets]
    D --> C
    C -- No --> E([Active logs in memory])
    E --> F{User captures\nnew snippet}
    F --> G[expiresAt = capturedAt + 7d]
    G --> H[Append to today's DailyLog]
    H --> E
```

---

## Flow 4: Overlay Dismiss (all exit paths)

```mermaid
flowchart LR
    A([Overlay visible]) --> B{Exit trigger}
    B -- "⎋ Escape" --> C[hideOverlay]
    B -- "⌘⇧M again" --> C
    B -- "Click outside panel" --> C
    B -- "Submit snippet" --> C
    C --> D([Overlay hidden,\napp continues in background])
```
