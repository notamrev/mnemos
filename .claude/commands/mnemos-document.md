# /mnemos-document

Update the docs/ diagrams and README to reflect a merged PR, or regenerate docs from scratch.

## Usage
- `/mnemos-document <PR#>` — update docs based on a specific merged PR
- `/mnemos-document init` — regenerate all docs from the current codebase state

## What to do

Argument: **$ARGUMENTS**

If no argument, ask: "PR number to document, or 'init' to regenerate from scratch?"

---

### Step 1 — Gather context

**If PR number given**, run in parallel:
```
gh pr view <N> --repo notamrev/mnemos --json title,body,author,baseRefName,headRefName,additions,deletions,files
gh pr diff <N> --repo notamrev/mnemos
```
Parse `Closes #N`, `Fixes #N`, `Resolves #N` from the PR body and fetch linked issues:
```
gh issue view <N> --repo notamrev/mnemos --json title,body
```

**If "init"**, read the current source tree:
```
find Mnemos -name "*.swift" | head -40
```
Then read all Swift source files to understand current models, stores, and app layer.

---

### Step 2 — Read current docs state

Read all four docs files in parallel:
```
docs/architecture/class-diagram.md
docs/architecture/entity-relation.md
docs/flows/user-flows.md
docs/flows/user-journeys.md
README.md
```

---

### Step 3 — Delegate to documentation agent

Use the Agent tool with `subagent_type: "general-purpose"`. Hand the agent:

- The PR title, body, and full diff (or Swift source files if init)
- Current contents of all five docs files
- The following update rules:

**Class diagram rules:**
- Add any new class, struct, enum, or actor introduced in the diff
- Update properties and methods if they changed
- Add/update associations (ownership, dependency arrows)
- Mark concurrency annotations: `<<@MainActor>>`, `<<@Observable>>`, `<<@unchecked Sendable>>`
- Remove deleted types
- Update the "Last updated by PR #N" header

**ER diagram rules:**
- Add any new `Codable` struct that represents a persisted entity
- Update fields if properties changed
- Update relationships if new foreign-key-style references appear
- Update the "Last updated by PR #N" header
- Update the Storage model section if persistence layer changed

**User flows rules:**
- Add a new flowchart section only if the PR introduces a new user-visible flow
- Update an existing flow if the PR changes control flow or adds a new exit path
- Do not add flows for internal implementation details (store internals, etc.)
- Update the "Last updated by PR #N" header

**User journeys rules:**
- Add a new journey only if the PR enables a meaningfully new user experience
- Keep journeys at the "day-in-the-life" level — not technical steps
- Do not add a journey for every PR; only when the user arc genuinely changes
- Update the "Last updated by PR #N" header

**README rules:**
- Update the Status table: mark completed items as "Shipped", move in-progress items forward
- Update the repo structure tree if new top-level files or folders were added
- Do not change the Architecture, Getting Started, or Contributing sections unless something fundamentally changed

Ask the agent to return each updated file as a clearly labelled fenced block:

```
### docs/architecture/class-diagram.md
<full updated file content>

### docs/architecture/entity-relation.md
<full updated file content>

### docs/flows/user-flows.md
<full updated file content>

### docs/flows/user-journeys.md
<full updated file content>

### README.md
<full updated file content>
```

---

### Step 4 — Apply updates

Write the agent's output to the respective files. Only write a file if the agent actually changed it — if unchanged, skip it.

---

### Step 5 — Commit

Stage and commit all changed docs files:
```
git add docs/ README.md
git commit -m "docs: update diagrams and README for PR #<N>

Co-Authored-By: Claude Sonnet 4.6 (1M context) <noreply@anthropic.com>"
```

If on a feature branch, push and note the commit SHA. If on main, push directly.

Report: which files changed, what was added/updated, commit SHA.
