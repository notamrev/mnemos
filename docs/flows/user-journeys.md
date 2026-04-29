# User Journeys

> Last updated by PR #19 — KnowledgeSnippet and DailyLog models

---

## Journey 1: First-time setup

```mermaid
journey
    title First-Time User — Installing and Enabling Mnemos
    section Install
      Download and open Mnemos.app: 4: User
      App requests Accessibility permission: 3: User, System
      User navigates to System Settings > Privacy: 2: User
      User enables Mnemos in Accessibility list: 4: User
    section First capture
      User presses ⌘⇧M for the first time: 5: User
      Overlay appears — user types a snippet: 5: User
      User adds tags and hits Return: 4: User
      Snippet saved — overlay closes: 5: User
    section Discovery
      User presses ⌘⇧M a few more times during the day: 5: User
      Realises muscle memory is forming: 5: User
```

---

## Journey 2: Daily knowledge capture loop

```mermaid
journey
    title Recurring User — A Day in Mnemos
    section Morning stand-up
      Hears something worth remembering: 4: User
      Presses ⌘⇧M immediately: 5: User
      Captures snippet while context is fresh: 5: User
    section Deep work session
      Discovers a non-obvious architectural pattern: 5: User
      Captures snippet + tags #architecture #swift: 4: User
      Returns to flow without losing momentum: 5: User
    section Code review
      Reviewer leaves useful comment: 3: User
      Captures key insight from review feedback: 4: User
      Tags #code-review #learnings: 3: User
    section End of day
      Briefly opens Mnemos to skim today's log: 3: User
      Sees 4-6 captures — satisfying snapshot of the day: 4: User
```

---

## Journey 3: Knowledge expires (rolling window)

```mermaid
journey
    title Ephemeral Knowledge — 7-Day Rolling Window
    section Day 1
      Captures a snippet about a one-off debug fix: 3: User
      Snippet stored with expiresAt = Day 8: 5: System
    section Day 5
      Snippet still visible and searchable: 4: User
      User references it when a similar bug appears: 5: User
    section Day 8
      App launches, prunes expired entries: 5: System
      Snippet silently removed — no longer relevant: 3: User
      User's knowledge base stays lean and current: 4: User
```

---

## Journey 4: Future — AI skill execution (post-MVP)

```mermaid
journey
    title Power User — Turning Captures into Executable Skills
    section Capture phase
      Accumulates snippets over a week on a topic: 4: User
      Tags consistently — e.g. #onboarding: 3: User
    section Skill creation
      Requests: "Create a skill from my #onboarding snippets": 5: User
      AI synthesises snippets into a structured prompt: 5: System
      User reviews and names the skill "Onboard a new hire": 4: User
    section Execution
      User triggers the skill on demand: 5: User
      AI runs the skill with current context: 5: System
      Output: actionable onboarding plan: 5: User
```
