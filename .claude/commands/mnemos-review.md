# /mnemos-review

Review a pull request: verify the diff against the linked ticket's acceptance criteria, check test coverage, validate logic, and produce a structured review report.

## What to do

PR number to review: **$ARGUMENTS**

If no PR number given, ask for one.

### Step 1 — Gather PR context

Run these in parallel:
```
gh pr view <N> --repo notamrev/mnemos --json title,body,author,baseRefName,headRefName,state,additions,deletions,changedFiles,files
gh pr diff <N> --repo notamrev/mnemos
gh pr checks <N> --repo notamrev/mnemos 2>/dev/null || true
```

### Step 2 — Find linked tickets
Parse the PR body for `Closes #N`, `Fixes #N`, `Resolves #N` references. For each linked issue:
```
gh issue view <N> --repo notamrev/mnemos --json title,body,labels
```

If a PR has no linked issue, FAIL the review immediately — every PR must close exactly one task issue. Report this as a blocker before going further.

### Step 3 — Delegate deep review to an agent

Use the Agent tool with `subagent_type: "general-purpose"`. Prompt the agent like a fresh code reviewer who has only the materials you hand them. Include:

- The PR title, body, file list, and full diff
- Each linked issue's full body (especially the AC checklist)
- The Mnemos development principles from `CLAUDE.md`:
  - No abstractions before they're needed
  - No comments unless WHY is non-obvious
  - TDD: tests must cover each AC
  - Conventional commit format
  - `@MainActor` for UI, `@Observable` for stores, `Codable` for models
  - Swift 6 concurrency: `@unchecked Sendable` only when access pattern is provably safe and documented

Ask the agent to produce a report covering exactly these sections:

1. **AC coverage** — for each AC in the linked issue(s), is it implemented? Cite the specific file:line. If any AC is unaddressed, flag explicitly.

2. **Test coverage** — for each AC, is there a corresponding `@Test` case? List test name → AC mapping. Flag any AC without test coverage as a coverage gap.

3. **Logic verification** — review the implementation against the issue's intent:
   - Does it actually do what the ticket asks?
   - Edge cases: empty input, nil, concurrent access, expired data, etc.
   - Concurrency: are `@MainActor` boundaries correct? Any data race risks?
   - Error handling: only at boundaries, not for impossible cases
   - Resource lifecycle: deinit, observer removal, file handle close

4. **Code quality** — measured against Mnemos principles only:
   - Unnecessary abstractions or premature generalization
   - Comments that describe WHAT instead of WHY
   - Backwards-compat shims, dead code, half-finished implementations
   - File/symbol naming inconsistencies with the rest of the codebase

5. **Scope creep** — any changes unrelated to the linked issue? Flag them. Suggest splitting into a separate PR.

6. **Verdict** — one of:
   - `APPROVE` — ship it
   - `APPROVE WITH SUGGESTIONS` — non-blocking improvements listed
   - `REQUEST CHANGES` — blockers must be fixed before merge
   - `FAIL` — fundamental issues (no linked ticket, breaks tests, wrong scope)

Tell the agent to be concise: cite file:line for every claim, no fluff.

### Step 4 — Post review

Show the agent's report to the user verbatim. Then ask: "Post this to the PR as a review comment?"

If yes:
```
gh pr review <N> --repo notamrev/mnemos --comment --body "<report>"
```
Or for an actual approval/request-changes:
```
gh pr review <N> --repo notamrev/mnemos --approve --body "<report>"
gh pr review <N> --repo notamrev/mnemos --request-changes --body "<report>"
```

### Step 5 — If verdict is APPROVE
Suggest the user merge via GitHub UI (squash and merge), then run `/mnemos-done <issue#>` afterwards.
