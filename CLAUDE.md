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
├── .claude/          # Claude Code commands, hooks, settings, install.sh
├── .githooks/        # Git hooks — enforced via core.hooksPath
├── topology/         # Service map, data flows, async contracts
├── .github/          # CI/CD workflows, issue templates
├── Mnemos/           # App source (Swift/SwiftUI)
├── MnemosTests/      # Unit tests (Swift Testing)
└── project.yml       # xcodegen spec — source of truth for Xcode project
```

## First-Time Setup
```bash
.claude/install.sh    # registers Claude commands globally + wires git hooks
xcodegen generate     # produces Mnemos.xcodeproj (gitignored)
```

---

## Development Workflow — MUST FOLLOW

### Branch rules
- **No commits to `main` directly** — enforced by `pre-commit` hook
- **No pushes to `main` directly** — enforced by `pre-push` hook
- Branch naming: `<type>/<issue#>-<short-description>`
  - `feat/12-knowledge-snippet-models`
  - `fix/9-hotkey-tap-recovery`
  - `test/7-storage-expiry`
  - `chore/17-update-dependencies`

### Commit message rules
Conventional commits — enforced by `commit-msg` hook:
```
<type>(<optional-scope>): <description>

Closes #<issue#>

Co-Authored-By: Claude Sonnet 4.6 (1M context) <noreply@anthropic.com>
```
Valid types: `feat` `fix` `test` `chore` `docs` `refactor` `style` `perf` `ci`

### TDD → PR → Merge cycle
1. Pick a task from the **Ready** column on the board
2. `git checkout -b feat/<issue#>-<description>`
3. **Write failing tests first** in `MnemosTests/`
4. Implement until tests pass (`⌘U`)
5. `/mnemos-pr <issue#>` — opens PR, moves card to In Review
6. Review, resolve comments, merge via GitHub UI
7. `/mnemos-done <issue#>` — closes issue, moves card to Done

### Every PR must
- Link to exactly one task issue (`Closes #N`)
- Have passing tests
- Be on a correctly-named branch

---

## Development Principles
- Ship the overlay first, storage second
- No abstractions before they're needed
- No comments unless the WHY is non-obvious
- Tests use Swift Testing (`@Test`, `#expect`) — no mocks for system APIs

## Key Decisions
- Active-only knowledge capture for v1 (user explicitly inputs, no passive monitoring)
- macOS native (Swift/SwiftUI) for best overlay/NSPanel behavior
- Ephemeral storage: JSON flat files, rolling 7-day window
- `CGEventTap` for global hotkey — requires Accessibility permission, not Input Monitoring
- `xcodegen` for project generation — commit `project.yml`, not `*.xcodeproj`
