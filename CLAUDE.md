# Mnemos

Company Brain — a macOS overlay app for capturing and structuring company knowledge.

## Product Vision
A lightweight macOS overlay (hotkey-triggered) that lets users record knowledge snippets throughout the day. Knowledge is tagged, dated, and made available as executable skills for AI automation.

## Architecture
- **Monorepo, monolithic first** — single repo, ship fast, split later if needed
- **macOS native** — Swift/SwiftUI, targets macOS 14+
- **Ephemeral MVP** — local storage only, rolling 7-day window, no cloud sync in v1

## Repo Structure
```
mnemos/
├── .claude/          # Claude Code commands, hooks, settings
├── topology/         # Service map, data flows, async contracts
├── .github/          # CI/CD workflows, issue templates
└── (app source)      # Swift package or Xcode project at root
```

## Development Principles
- Ship the overlay first, storage second
- No abstractions before they're needed
- Every PR has a linked GitHub issue

## Key Decisions
- Active-only knowledge capture for v1 (user explicitly inputs, no passive monitoring)
- macOS native (Swift/SwiftUI) for best overlay/NSPanel behavior
- Ephemeral storage: JSON flat files, rolling 7-day window
