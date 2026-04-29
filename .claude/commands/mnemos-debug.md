# /mnemos-debug

Diagnose and fix a build or runtime issue in Mnemos.

## What to do

The user is debugging: **$ARGUMENTS**

### Step 1 — Understand the failure
If the user pasted an error, parse it carefully:
- Xcode build errors include file path + line number — read that file at that line first
- Runtime crashes include a stack trace — identify the top non-system frame
- Swift 6 concurrency errors: actor isolation, Sendable, data race warnings

### Step 2 — Read before writing
Always read the failing file(s) before suggesting changes. Never guess at line content.

### Step 3 — Diagnose root cause
Common Mnemos-specific issues:
- **CGEventTap nil**: Accessibility permission not granted or granted to stale binary → System Settings → Privacy & Security → Accessibility
- **`@MainActor` isolation errors**: class or method needs `@MainActor` annotation, or caller needs `Task { @MainActor in ... }`
- **Swift 6 Sendable**: crossing actor boundaries — use `@unchecked Sendable` only when access pattern is provably safe; document why
- **xcodegen out of sync**: new file added but project not regenerated → run `xcodegen generate`
- **Build succeeds but hotkey silent**: tap disabled by OS — `reEnable()` is called on `tapDisabledByTimeout`

### Step 4 — Fix minimally
Apply the smallest change that fixes the root cause. Do not refactor surrounding code. Do not add error handling for cases that can't happen.

### Step 5 — Verify
If it's a build error, run:
```
xcodebuild -project Mnemos.xcodeproj -scheme Mnemos -destination "platform=macOS" build 2>&1 | grep -E "error:|warning:|BUILD"
```

Report what was changed and why.
