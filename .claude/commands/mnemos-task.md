# /mnemos-task

Create an atomic task card on the Mnemos project board.

## Project constants
- Repo: `notamrev/mnemos`
- Project number: `2`, Project ID: `PVT_kwHOBLrHWc4BWElA`
- Type field: `PVTSSF_lAHOBLrHWc4BWElAzhRcKtc` — Task: `bbb277b2`, Test: `54f50182`
- Status field: `PVTSSF_lAHOBLrHWc4BWElAzhRbvBU`
  - Backlog: `f75ad846` | Ready: `e18bf179` | In Progress: `47fc9ee4` | In Review: `aba860b9` | Done: `98236657`

## Agile rules for tasks
- One task = one PR = one reviewable unit of work
- Must be completable in a single session
- Must reference a parent epic in the body ("Part of Epic #N")
- Title is a verb phrase: "Implement X", "Add Y", "Fix Z"

## What to do

The user wants to create a task for: **$ARGUMENTS**

If the user didn't specify an epic number, ask which epic this belongs to before proceeding.

1. Create the issue with a concise body: what it does, acceptance criteria (2–4 bullets), parent epic reference.
   ```
   gh issue create --repo notamrev/mnemos --title "<verb phrase>" --body "..."
   ```

2. Add to board, get item ID, set Type = Task, set Status = Ready (unless user specifies otherwise):
   ```
   gh project item-add 2 --owner notamrev --url <issue-url>
   gh project item-edit --project-id PVT_kwHOBLrHWc4BWElA --id <item-id> \
     --field-id PVTSSF_lAHOBLrHWc4BWElAzhRcKtc --single-select-option-id bbb277b2
   gh project item-edit --project-id PVT_kwHOBLrHWc4BWElA --id <item-id> \
     --field-id PVTSSF_lAHOBLrHWc4BWElAzhRbvBU --single-select-option-id e18bf179
   ```

3. Report issue number and URL.
