# /mnemos-pr

Create a pull request for the current branch following Mnemos project rules.

## Project rules
- Every PR must link to an issue (task card, not an epic)
- PR title = issue title (keep it short, under 70 chars)
- Branch name should reflect the task: `feat/<short-description>` or `fix/<short-description>`
- One PR per task — no bundling unrelated changes

## What to do

The user wants to open a PR for: **$ARGUMENTS**

If no issue number is given, ask for it before proceeding.

### Step 1 — Sanity checks
```
git status          # ensure no uncommitted changes
git diff main...HEAD --stat   # show what's changing
```
If there are uncommitted changes, stop and tell the user.

### Step 2 — Confirm branch
If on `main`, stop and ask the user to create a feature branch first:
```
git checkout -b feat/<description>
```

### Step 3 — Push if needed
```
git push -u origin HEAD
```

### Step 4 — Draft PR body
- **Summary**: 2–3 bullets on what changed and why
- **Test plan**: checklist of how to verify this works manually + which automated tests cover it
- **Linked issue**: `Closes #<N>`

### Step 5 — Create PR
```
gh pr create \
  --title "<issue title>" \
  --body "..." \
  --repo notamrev/mnemos
```

### Step 6 — Move board card to In Review
Look up the project item for the linked issue and set Status = In Review (`aba860b9`):
```
gh project item-edit --project-id PVT_kwHOBLrHWc4BWElA --id <item-id> \
  --field-id PVTSSF_lAHOBLrHWc4BWElAzhRbvBU --single-select-option-id aba860b9
```

Return the PR URL.
