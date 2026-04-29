# /mnemos-feat

Set up and begin implementing a new feature following the TDD → PR → Merge workflow.

## Branch rules
- Branch name MUST follow: `feat/<issue#>-<short-description>` (e.g. `feat/12-knowledge-snippet-models`)
- No commits to main — all work lands via PR only
- Tests must be written before or alongside the implementation (TDD)
- One branch = one issue = one PR

## Project constants
- Repo: `notamrev/mnemos`
- Project ID: `PVT_kwHOBLrHWc4BWElA`
- Type field: `PVTSSF_lAHOBLrHWc4BWElAzhRcKtc` — Task: `bbb277b2`, Test: `54f50182`
- Status field: `PVTSSF_lAHOBLrHWc4BWElAzhRbvBU`
  - In Progress: `47fc9ee4`

## What to do

The user wants to implement: **$ARGUMENTS**

### Step 1 — Clarify
If no issue number is given, ask which task card this maps to before proceeding.

### Step 2 — Create branch
```
git checkout -b feat/<issue#>-<short-description>
```
Verify we are NOT on main before writing any code.

### Step 3 — Create task + test issue pair (if not already created)
If the task issue doesn't exist yet, create it with `/mnemos-task` first.
Then create a paired test issue titled `Tests: <feature>`.

Set both to Type: Task/Test, Status: In Progress.

### Step 4 — Write tests FIRST (TDD)
Create `MnemosTests/<Feature>Tests.swift` with `@Test` cases for each AC in the issue.
Tests will fail — that is correct. Commit the failing tests:
```
git add MnemosTests/
git commit -m "test(<scope>): add failing tests for <feature>"
```

### Step 5 — Implement
- Read all relevant existing files before writing
- Run `xcodegen generate` after adding new source files
- Follow patterns: `@MainActor` for UI, `@Observable` for stores, `Codable` for models
- No abstractions beyond what the AC requires
- No comments unless the WHY is non-obvious

Commit in small logical units:
```
git commit -m "feat(<scope>): <what and why>"
```

### Step 6 — Make tests pass
Run tests via:
```
xcodebuild test -project Mnemos.xcodeproj -scheme Mnemos -destination "platform=macOS" 2>&1 | grep -E "passed|failed|error:"
```
All tests must pass before opening a PR.

### Step 7 — Open PR
Use `/mnemos-pr <issue#>` — do not push to main.

### Step 8 — Report
- Branch created
- Issues created or linked
- Test cases written (failing → passing)
- Build status
