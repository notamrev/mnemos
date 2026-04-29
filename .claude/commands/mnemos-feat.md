# /mnemos-feat

Set up and begin implementing a new feature — creates a task card + paired test card, moves task to In Progress, then scaffolds the implementation.

## Project constants
- Repo: `notamrev/mnemos`
- Project ID: `PVT_kwHOBLrHWc4BWElA`
- Type field: `PVTSSF_lAHOBLrHWc4BWElAzhRcKtc` — Task: `bbb277b2`, Test: `54f50182`
- Status field: `PVTSSF_lAHOBLrHWc4BWElAzhRbvBU`
  - Ready: `e18bf179` | In Progress: `47fc9ee4`

## What to do

The user wants to implement: **$ARGUMENTS**

### Step 1 — Clarify if needed
If the feature description is ambiguous or no epic number is given, ask before proceeding.

### Step 2 — Create task + test issue pair
Create TWO issues:
1. Feature task — title: `"Implement <feature>"`, body includes ACs and parent epic reference
2. Test task — title: `"Tests: <feature>"`, body lists the test cases that must pass

Add both to the board. Set:
- Feature task: Type=Task, Status=In Progress
- Test task: Type=Test, Status=In Progress

### Step 3 — Implement
- Read relevant existing files before writing anything new
- Run `xcodegen generate` if any new source files are added
- Write the implementation following the patterns in the codebase:
  - SwiftUI views in `Mnemos/<Feature>/`
  - Models in `Mnemos/Models/`
  - Services in their own file alongside the feature
  - `@MainActor` for UI classes, `@unchecked Sendable` only when crossing actor boundaries with documented reasoning
- No abstractions beyond what the task requires
- No comments unless the WHY is non-obvious

### Step 4 — Write tests
Add test file to `MnemosTests/` covering the cases from the test task issue.
Use Swift Testing (`@Test`, `#expect`). No mocks for system APIs — test pure logic only.

### Step 5 — Build check
Run `xcodebuild -project Mnemos.xcodeproj -scheme Mnemos -destination "platform=macOS" build 2>&1 | tail -20` to verify it compiles.

### Step 6 — Report
- What was implemented
- Test cases added
- Issue numbers created
- Any deferred items
