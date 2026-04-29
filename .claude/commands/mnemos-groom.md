# /mnemos-groom

Review and groom the Mnemos project board — surface blockers, stale items, and suggest what to work on next.

## What to do

### Step 1 — Pull board state
```
gh project item-list 2 --owner notamrev --format json
gh issue list --repo notamrev/mnemos --state open --limit 50
```

### Step 2 — Analyse and report

Group items by status and type. Report:

**In Progress** — anything been in progress for a while with no linked PR? Flag as potentially stale.

**Ready** — list all Ready tasks, check dependencies:
- Does this task depend on another task that isn't Done yet?
- Flag blocked items explicitly

**Backlog** — are there any backlog tasks that are clearly prerequisite to Ready items? Suggest promoting them to Ready.

**Epics** — for each epic with In Progress tasks, count checked vs unchecked ACs. Report % complete.

### Step 3 — Suggest sprint

Based on the analysis, suggest the optimal next 2–3 tasks to work on, explaining:
- Why these first (dependencies, value delivered)
- Any tasks that should be paired (e.g. a feature + its test task)
- Anything that should be split further if it looks too large

### Step 4 — Identify missing test coverage

List any Done feature tasks that don't have a corresponding Done test task. These are coverage gaps.

Keep the report concise — one line per item unless flagging a problem.
