# Mnemos

> Company Brain — capture how your company works, make it executable for AI.

A lightweight macOS overlay app (triggered by `⌘⇧M`) that lets you record knowledge snippets throughout the day. Knowledge is tagged, dated, and stored in a rolling 7-day local window — the foundation for AI-executable skills.

---

## Status

| Area | State |
|------|-------|
| Overlay shell (hotkey + NSPanel) | Shipped |
| KnowledgeSnippet + DailyLog models | Shipped |
| KnowledgeStore (JSON persistence) | In progress |
| Capture UI (overlay form) | Backlog |
| Snippet browser | Backlog |
| AI skill execution | Post-MVP |

---

## Architecture

**Stack:** Swift 6 · SwiftUI · AppKit · macOS 14+

**Key design decisions:**
- `CGEventTap` for global `⌘⇧M` hotkey — requires Accessibility permission only (not Input Monitoring)
- `NSPanel` with `.nonactivatingPanel` mask — overlay appears without stealing focus
- Ephemeral local storage — JSON flat files, rolling 7-day window, no cloud sync in v1
- `@Observable` stores, `@MainActor` UI, `Codable` models — Swift 6 strict concurrency throughout

**Docs:**
- [Class diagram](docs/architecture/class-diagram.md)
- [Entity relationship](docs/architecture/entity-relation.md)
- [User flows](docs/flows/user-flows.md)
- [User journeys](docs/flows/user-journeys.md)

---

## Getting Started

**Prerequisites:** Xcode 16+, `xcodegen` (`brew install xcodegen`)

```bash
# 1. Clone
git clone git@github.com:notamrev/mnemos.git && cd mnemos

# 2. Register Claude Code commands + wire git hooks
.claude/install.sh

# 3. Generate Xcode project
xcodegen generate

# 4. Open and run
open Mnemos.xcodeproj
```

On first launch, macOS will prompt for Accessibility permission (required for the global hotkey). Grant it in **System Settings → Privacy & Security → Accessibility**.

---

## Development Workflow

All work follows a strict **TDD → PR → Merge** cycle. No direct commits to `main`.

```
Pick task (Ready column) → feat/<issue#>-<desc> branch →
write failing tests → implement → tests pass →
/mnemos-pr <issue#> → review → merge
```

**Useful Claude Code commands (install with `.claude/install.sh`):**

| Command | Purpose |
|---------|---------|
| `/mnemos-feat <issue#>` | Start a new feature on the right branch |
| `/mnemos-pr <issue#>` | Open a PR linked to the task issue |
| `/mnemos-review <PR#>` | Agent-driven PR review against AC checklist |
| `/mnemos-document <PR#>` | Update docs/ diagrams and README after a merge |
| `/mnemos-done <issue#>` | Close issue and move board card to Done |
| `/mnemos-groom` | Groom the project board, surface blockers |

**Branch naming:** `<type>/<issue#>-<short-description>`
**Commit format:** `<type>(<scope>): <description>` (Conventional Commits, enforced by hook)

---

## Repo Structure

```
mnemos/
├── .claude/              # Claude Code commands, hooks, install.sh
├── .githooks/            # pre-commit, commit-msg, pre-push (enforced)
├── .github/              # CI workflows (disabled until MVP)
├── docs/
│   ├── architecture/     # class-diagram.md, entity-relation.md
│   └── flows/            # user-flows.md, user-journeys.md
├── Mnemos/               # App source (Swift/SwiftUI)
│   ├── App/              # AppDelegate, HotKeyManager
│   ├── Models/           # KnowledgeSnippet, DailyLog
│   ├── Overlay/          # OverlayWindowController
│   └── Resources/        # Assets, Info.plist, entitlements
├── MnemosTests/          # Unit tests (Swift Testing)
└── project.yml           # xcodegen spec — source of truth
```

---

## Contributing

All work is tracked on the [GitHub Project Board](https://github.com/orgs/notamrev/projects/2). Every PR must close exactly one task issue. See `CLAUDE.md` for the full development rulebook.
