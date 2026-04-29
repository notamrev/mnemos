# /mnemos-done

Mark a task as done: close the issue, update the board, and prompt for a PR if one isn't open yet.

## Project constants
- Repo: `notamrev/mnemos`
- Project ID: `PVT_kwHOBLrHWc4BWElA`
- Status field: `PVTSSF_lAHOBLrHWc4BWElAzhRbvBU`, Done option ID: `98236657`

## What to do

The user is finishing task: **$ARGUMENTS**

If no issue number is given, ask for it.

### Step 1 — Verify done
Check the issue's ACs. If any are unchecked, list them and ask the user to confirm they're all actually complete before proceeding.

### Step 2 — Check for open PR
```
gh pr list --repo notamrev/mnemos --state open
```
If no PR is linked to this issue, ask: "Should I create a PR for this work before closing?"

### Step 3 — Update board status to Done
Get the project item ID for this issue number:
```
gh project item-list 2 --owner notamrev --format json
```
Then:
```
gh project item-edit --project-id PVT_kwHOBLrHWc4BWElA --id <item-id> \
  --field-id PVTSSF_lAHOBLrHWc4BWElAzhRbvBU --single-select-option-id 98236657
```

### Step 4 — Close the issue
```
gh issue close <number> --repo notamrev/mnemos --comment "Completed."
```

### Step 5 — Check if parent epic ACs are all done
Look at the parent epic issue body and report how many ACs are now checked vs remaining.

### Step 6 — Suggest next task
Look at the board's Ready column and suggest the highest-priority next task to pick up.
