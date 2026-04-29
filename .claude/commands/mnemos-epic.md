# /mnemos-epic

Create a new Mnemos epic following project conventions.

## Project constants
- Repo: `notamrev/mnemos`
- Project number: `2`, Project ID: `PVT_kwHOBLrHWc4BWElA`
- Type field ID: `PVTSSF_lAHOBLrHWc4BWElAzhRcKtc`, Epic option ID: `fed61231`
- Status field ID: `PVTSSF_lAHOBLrHWc4BWElAzhRbvBU`, Backlog option ID: `f75ad846`

## What to do

The user wants to create an epic for: **$ARGUMENTS**

1. Draft an epic issue body following this structure exactly:
   - **Goal** — one sentence on what this epic delivers
   - **User Story** — "As a user, I can X so that Y"
   - **Acceptance Criteria** — checklist of testable ACs (each maps to one future task card)
   - **Out of Scope (v1)** — explicit exclusions
   - **Tech Notes** — implementation hints, dependencies on other epics

2. Create the issue:
   ```
   gh issue create --repo notamrev/mnemos --title "Epic: <title>" --body "..."
   ```

3. Add it to the project board:
   ```
   gh project item-add 2 --owner notamrev --url <issue-url>
   ```

4. Get the new item's project ID:
   ```
   gh project item-list 2 --owner notamrev --format json
   ```

5. Set Type = Epic (stays in Epic column, never moves through kanban):
   ```
   gh project item-edit --project-id PVT_kwHOBLrHWc4BWElA --id <item-id> \
     --field-id PVTSSF_lAHOBLrHWc4BWElAzhRcKtc --single-select-option-id fed61231
   ```

6. Report back: issue number, URL, and the ACs drafted so the user can validate before we create task cards.
