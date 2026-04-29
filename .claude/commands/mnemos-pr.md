# /mnemos-pr

Create a pull request for the current branch. Enforces all branch and PR rules before opening.

## Rules
- Must be on a feature branch (never main)
- Branch name must match: `(feat|fix|test|chore|docs|refactor)/<issue#>-<description>`
- All tests must pass before PR is opened
- PR title = task issue title
- Every PR must close exactly one task issue

## Project constants
- Repo: `notamrev/mnemos`
- Project ID: `PVT_kwHOBLrHWc4BWElA`
- Status field: `PVTSSF_lAHOBLrHWc4BWElAzhRbvBU`
  - In Review: `aba860b9`

## What to do

Issue number (if given): **$ARGUMENTS**

### Step 1 — Guard: check branch
```
git symbolic-ref --short HEAD
```
If the branch is `main` — stop. Tell the user to create a feature branch.
If the branch name doesn't match the naming convention — stop and show the correct format.

### Step 2 — Guard: uncommitted changes
```
git status --short
```
If there are uncommitted changes — stop and ask the user to commit or stash them.

### Step 3 — Run tests
```
xcodebuild test -project Mnemos.xcodeproj -scheme Mnemos -destination "platform=macOS" 2>&1 | tail -20
```
If any tests fail — stop. Show the failing test names. Do not open a PR with failing tests.

### Step 4 — Fetch issue title
```
gh issue view <issue#> --repo notamrev/mnemos --json title,body
```

### Step 5 — Push branch
```
git push -u origin HEAD
```

### Step 6 — Create PR
```
gh pr create \
  --repo notamrev/mnemos \
  --title "<issue title>" \
  --body "$(cat <<'EOF'
## Summary
- <bullet: what changed>
- <bullet: why>

## Test plan
- [ ] Tests pass: `⌘U` in Xcode
- [ ] Manual verification: <describe golden path>

## Linked issue
Closes #<issue#>
EOF
)"
```

### Step 7 — Move board card to In Review
Get item ID for the issue, then:
```
gh project item-edit --project-id PVT_kwHOBLrHWc4BWElA --id <item-id> \
  --field-id PVTSSF_lAHOBLrHWc4BWElAzhRbvBU --single-select-option-id aba860b9
```

Return the PR URL.
