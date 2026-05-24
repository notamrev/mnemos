# Mnemos Product Roadmap — Local Brain → Team Brain

## Context

Mnemos is currently a manual-input, single-user, macOS overlay with ephemeral JSON storage (7-day rolling window). The product vision is to evolve it into a **team knowledge network**: each developer has a private local brain, teams can query each other's shared brains in English or mnemos-sql, and AI (Claude) can access the brain directly via an API key or MCP server. Data input grows from manual-only to include automatic capture from VS Code, terminal, screen, and clipboard.

This plan defines the phases, technology decisions, and epics required to reach that end state without breaking the current MVP workflow.

---

## Guiding Principles

- **Local-first, zero friction** — individual brain requires no server, no Docker, no account
- **Cloud-agnostic team layer** — on-premise or client cloud; Docker Compose as the deployment primitive
- **Privacy by default** — all automatic capture is opt-in; snippets are private unless explicitly shared
- **Monolithic-first** — no microservices split until a boundary forces it
- **macOS native stays** — overlay remains Swift/SwiftUI; new components (MCP server, VS Code extension, sync server) are separate binaries/packages
- **Beta-first SDLC** — ship the smallest working thing to real users before building infrastructure; validate before scaling

---

## Current State

| Layer | State | Format |
|---|---|---|
| Capture UI | ✅ Shipped | Manual text + tags |
| Browse UI | ✅ Shipped | Day-grouped list, tag filter, search |
| Storage | ✅ Shipped | Flat JSON, 7-day rolling |
| Skills Compiler | 🔄 In Progress (Epic #5) | group snippets by tag → skills.json |
| AI integration | ❌ None | — |
| Auto-capture | ❌ None | — |
| Team sync | ❌ None | — |

---

## Revised Roadmap — Beta-First Staging

The original roadmap optimised for technical correctness (SQLite before AI, infrastructure before users). The revised staging optimises for **getting real developers using a real brain as fast as possible**, then hardening the infrastructure once value is proven.

```
ORIGINAL ORDER          REVISED ORDER
─────────────────       ──────────────────────────────────────
Phase 1: MVP       →    Stage 1: Complete MVP + Skills Compiler  ← NOW
Phase 2: SQLite    →    Stage 4: SQLite + MCP (deferred)
Phase 3: MCP       →    Stage 4: (same, deferred)
Phase 4: Auto-cap  →    Stage 2: VS Code Auto-capture (moved up)
Phase 5: Team      →    Stage 3: Shared Brain via Git (simplified)
                        Stage 4: SQLite + Full MCP (after beta proven)
                        Stage 5: Team PostgreSQL (scale-up)
```

**Why this order:** Auto-capture and a shared brain are the features that make the product *feel* like magic to a beta team. SQLite and a full MCP server are infrastructure investments that pay off at scale — they come after beta validates the value, not before.

---

## Architecture Evolution

```
TODAY (Stage 1)
  [macOS Overlay] ──► [KnowledgeStore] ──► [~/Mnemos/YYYY-MM-DD.json]
                                                        │
                                           [SkillsCompiler] ──► [skills.json]

STAGE 2 (Auto-capture)
  [VS Code Ext]   ──► POST localhost:40842/capture ──► [CaptureEndpoint (Swift)]
                                                              │
  [macOS Overlay] ──────────────────────────────────► [KnowledgeStore] ──► [JSON]
                                                              │
                                                   [SkillsCompiler] ──► [skills.json]

STAGE 3 (Shared Brain via Git)
  each dev: [skills.json] ──► push to shared repo ──► CI merge ──► [team-brain.json]
  Claude Code: @file team-brain.json  ←── load ─────────────────────────────────────

STAGE 4 (Infrastructure hardening)
  [macOS Overlay] ──► [KnowledgeStore] ──► [SQLite local DB]
                                            (FTS5 + vector via sqlite-vec)
  [Claude Code]   ──► [mnemos-mcp]     ──► [SQLite]  (MCP stdio server)
  [Claude API]    ──►  in-app query UI  ──► [SQLite]

STAGE 5 (Team scale-up)
  [each dev SQLite] ──► [mnemos-sync] ──► [PostgreSQL + pgvector]
  [Team query UI] ──► [mnemos-sql / NL query] ──► [PostgreSQL]
```

---

## Stage 1 — Complete MVP + Skills Compiler
**Goal:** Finish Epic #5 (Skills Compiler). No new features.

**Issues:**
- #46 SkillsCompiler core transform: group snippets by tag, emit skills.json (Ready)
- #47 Tests: SkillsCompiler grouping, untagged → general, JSON schema (Ready)
- #48 Auto-compile skills.json with 5s debounce after each save (Backlog)
- #49 Menu bar: add 'Export Skills' action to trigger manual recompile (Backlog)
- #30 Chore: set DEVELOPMENT_TEAM in project.yml (Ready)

**Output:** Each developer has a `skills.json` compiled from their local brain, grouped by tag, readable by Claude Code as a `@file` context reference.

---

## Stage 2 — VS Code Auto-capture
**Goal:** Build a minimal VS Code extension + local Swift HTTP receiver so the brain fills itself automatically as developers work — no manual overlay interaction required.

**Why before SQLite:** Auto-capture is the key unlock — the brain goes from "thing you remember to fill" to "thing that fills itself." Proving this on the existing JSON store is faster and lower risk than migrating storage first.

### Local HTTP Capture Endpoint (Swift)
A lightweight HTTP server embedded in the app listening on `localhost:40842`.

```
POST /capture
{
  "source": "vscode",
  "content": "Opened AuthService.swift in mnemos project",
  "tags": ["swift", "auth"],
  "metadata": { "file_path": "/path/to/file", "project": "mnemos" }
}
```

- Only accepts localhost connections (security gate)
- Writes to existing `KnowledgeStore.save(_:)`
- Starts when app launches, stops cleanly on quit

**New files:**
- `Mnemos/Capture/CaptureServer.swift` — HTTP listener
- `Mnemos/Capture/CaptureRequestHandler.swift` — decode + validate + save

### VS Code Extension (TypeScript)
**File open/save events (default on):**
- File open → POST `{ source: 'vscode', content: 'Opened <filename>', tags: [<language>], metadata: { file_path, project } }`
- File save → POST `{ source: 'vscode', content: 'Saved <filename>', tags: [<language>], metadata: { file_path, project } }`
- Filters out node_modules, .git, system paths

**Terminal command capture (default off, opt-in):**
- VS Code setting: `mnemos.captureTerminal` (boolean, default false)
- Captures: git commit/push/merge, npm/yarn/pnpm run scripts, non-zero exit commands
- Filters noise: ls, cd, cat, clear, commands under 10 chars

**Key files:**
- `extensions/vscode/src/extension.ts`
- `extensions/vscode/src/captureClient.ts`
- `extensions/vscode/src/filterEngine.ts`
- `extensions/vscode/package.json`

### Tests
- Swift: endpoint accepts valid POST → snippet in KnowledgeStore; rejects non-localhost; 400 on bad JSON
- VS Code: file open payload shape; node_modules filtered; terminal gate; noise filter; graceful no-op when daemon offline

**Issues:**
- #53 feat: local HTTP capture endpoint in Swift (Ready)
- #54 feat: VS Code extension — file open/save capture (Backlog)
- #55 feat: VS Code extension — terminal command capture, opt-in (Backlog)
- #56 test: capture endpoint + VS Code extension event filtering (Backlog)

**Output:** Developer installs VS Code extension → opens a file → snippet appears in Browse within 5s. Zero manual input.

---

## Stage 3 — Shared Brain via Git
**Goal:** Each developer's `skills.json` gets committed to a shared internal repo. A CI job merges them into `team-brain.json`. Any team member or Claude Code instance loads it as context — no server, no Docker, no account required.

**Why before PostgreSQL:** For a 5–10 person beta team, a compiled JSON file in a shared repo is enough to prove value. Ships in days, not weeks.

### Merge-Skills Script
Reads all `skills/<developer>.json` files → deduplicates identical content (case-insensitive) → emits `team-brain.json` attributed by author.

**Input** (`skills/alice.json`):
```json
{
  "swift": ["Use @MainActor for UI updates"],
  "auth": ["Tokens expire after 5 minutes"]
}
```

**Output** (`team-brain.json`):
```json
{
  "swift": [
    { "author": "alice", "content": "Use @MainActor for UI updates" },
    { "author": "bob",   "content": "Prefer structured concurrency over GCD" }
  ],
  "auth": [
    { "author": "alice", "content": "Tokens expire after 5 minutes" }
  ]
}
```

**New files:**
- `scripts/merge-skills.js` — merge script (Node.js)
- `.github/workflows/compile-team-brain.yml` — triggers on push to skills/

### CI Job
Triggers when any `skills/*.json` changes on push to main → runs merge script → auto-commits updated `team-brain.json`. Idempotent, completes in under 30s.

### Developer Onboarding
- Install Mnemos + VS Code extension
- Clone shared brain repo
- After each session: push updated `skills.json` to `skills/<your-name>.json`
- Load `team-brain.json` in Claude Code via `@file`

**Issues:**
- #57 feat: merge-skills script (Backlog)
- #58 ci: auto-compile team-brain.json on push (Backlog)
- #59 docs: team onboarding guide (Backlog)

**Output:** Dev A pushes skills.json → CI merges → Dev B pulls → Claude Code answers questions about the team's collective knowledge.

---

## Stage 4 — Storage Foundation + Full MCP
**Goal:** Migrate from flat JSON to SQLite. Build the mnemos-mcp stdio server. Enable real-time queries. Unlocks after beta validates value from Stages 1–3.

### Why SQLite
- FTS5 enables full-text search across all snippets
- `sqlite-vec` adds vector column for semantic search
- Embedded — no server, no Docker
- Same SQL dialect as PostgreSQL (easy port for Stage 5)
- Enables real-time MCP queries (not possible with static skills.json)

### Schema
```sql
CREATE TABLE snippets (
  id          TEXT PRIMARY KEY,
  content     TEXT NOT NULL,
  tags        TEXT NOT NULL,             -- JSON array
  source      TEXT NOT NULL DEFAULT 'manual',
  captured_at INTEGER NOT NULL,
  expires_at  INTEGER NOT NULL,
  metadata    TEXT                       -- JSON blob
);

CREATE VIRTUAL TABLE snippets_fts USING fts5(content, tags, content='snippets', content_rowid='rowid');

CREATE VIRTUAL TABLE snippet_embeddings USING vec0(
  snippet_id TEXT PRIMARY KEY,
  embedding  FLOAT[1536]
);
```

### Migration
On first launch after upgrade: load all JSON files → insert into SQLite → rename `.json` → `.migrated`.

### mnemos-mcp (MCP stdio server)
Standalone binary. Claude Code adds it to `~/.claude/settings.json`.

**Exposed tools:**
```
search_brain(query, limit?)     → snippet[]   -- FTS + semantic reranking
get_snippets_for_file(path)     → snippet[]   -- by metadata.file_path
add_snippet(content, tags)      → snippet     -- capture from Claude Code
list_tags(prefix?)              → string[]    -- all tags in local brain
```

**New files:**
- `Mnemos/Storage/KnowledgeDatabase.swift` — SQLite wrapper
- `Mnemos/Storage/KnowledgeStore.swift` — swap file I/O for DB calls, keep same public API
- `Mnemos/Models/KnowledgeSnippet.swift` — add `source: SnippetSource` field
- `mnemos-mcp/` — new Swift Package (CLI target)
- `MnemosTests/KnowledgeDatabaseTests.swift`

**Issues (to create after Stage 3 complete):**
- Epic #7: Storage: SQLite migration + FTS
- Epic #8: AI: mnemos-mcp stdio server
- Epic #9: AI: Claude API key + Ask tab

---

## Stage 5 — Team Brain (Scale-Up)
**Goal:** Replace the git-based shared brain with a real-time PostgreSQL sync. Enables live queries, semantic search across the team, and the mnemos-sql query language. Unlocks after Stage 4 proven.

### Team PostgreSQL Schema
```sql
CREATE TABLE members (
  id UUID PRIMARY KEY, name TEXT, email TEXT UNIQUE, team_id UUID NOT NULL
);

CREATE TABLE snippets (
  id          UUID PRIMARY KEY,
  member_id   UUID REFERENCES members(id),
  content     TEXT NOT NULL,
  tags        JSONB NOT NULL,
  source      TEXT NOT NULL,
  captured_at TIMESTAMPTZ NOT NULL,
  expires_at  TIMESTAMPTZ,
  is_shared   BOOLEAN DEFAULT FALSE,
  embedding   VECTOR(1536),
  metadata    JSONB
);

CREATE INDEX ON snippets USING ivfflat (embedding vector_cosine_ops);
CREATE INDEX ON snippets USING GIN (tags);
```

### Sync Protocol
- **Push**: local daemon POSTs new shared snippets to team server on save
- **Pull**: periodic background sync (configurable interval)
- **Conflict**: last-write-wins per snippet ID
- **Privacy**: only `is_shared = TRUE` snippets leave the device

### mnemos-sql Query Language
```sql
FROM @alice SEARCH "authentication token refresh"
FROM @team  TAGGED "swift" SINCE 7d
FROM @me    RECENT 20
```

**Issues (to create after Stage 4 complete):**
- Epic #12: Team sync server + Docker Compose
- Epic #13: mnemos-sql query layer
- Epic #14: Auto-capture terminal, JetBrains, clipboard, screen

---

## Epics Map

| Epic | Title | Stage | Status |
|---|---|---|---|
| #1 | Overlay Shell | 1 | ✅ Done |
| #2 | Knowledge Capture | 1 | ✅ Done |
| #3 | Ephemeral Storage | 1 | ✅ Done |
| #4 | Browse & Review | 1 | ✅ Done |
| #5 | Skills Compiler | 1 | 🔄 In Progress |
| #6 | App Polish & Distribution | 1 | 🔄 In Progress |
| #51 | VS Code Auto-capture | 2 | 📋 Planned |
| #52 | Shared Brain via Git | 3 | 📋 Planned |
| #7 | Storage: SQLite + FTS | 4 | 🔒 Locked (after Stage 3) |
| #8 | AI: mnemos-mcp stdio server | 4 | 🔒 Locked |
| #9 | AI: Claude API key + Ask tab | 4 | 🔒 Locked |
| #12 | Team sync + Docker Compose | 5 | 🔒 Locked (after Stage 4) |
| #13 | Team: mnemos-sql | 5 | 🔒 Locked |
| #14 | Auto-capture: terminal/JB/clipboard/screen | 5 | 🔒 Locked |

---

## Critical Files (Across All Stages)

| File | Change | Stage |
|---|---|---|
| `Mnemos/SkillsCompiler/SkillsCompiler.swift` | New: group by tag, emit skills.json | 1 |
| `Mnemos/Capture/CaptureServer.swift` | New: localhost HTTP receiver | 2 |
| `extensions/vscode/src/extension.ts` | New: VS Code extension | 2 |
| `scripts/merge-skills.js` | New: merge per-dev skills.json | 3 |
| `.github/workflows/compile-team-brain.yml` | New: CI auto-compile | 3 |
| `Mnemos/Storage/KnowledgeStore.swift` | Swap JSON I/O for SQLite | 4 |
| `Mnemos/Models/KnowledgeSnippet.swift` | Add `source: SnippetSource` | 4 |
| `mnemos-mcp/Sources/main.swift` | New: MCP stdio server | 4 |
| `docker-compose.yml` | New: team server | 5 |

---

## Verification

### Stage 1 (Skills Compiler)
- `xcodebuild test` — all tests pass
- Manual: capture 3 snippets with different tags → skills.json groups them correctly → `@file skills.json` in Claude Code returns tag-organised knowledge

### Stage 2 (Auto-capture)
- Toggle VS Code extension on → open a file → overlay Browse shows new snippet within 5s, no manual input
- Terminal capture off by default → enable setting → run `git commit` → snippet appears

### Stage 3 (Shared Brain)
- Dev A pushes skills.json → CI merge runs → Dev B pulls → Claude Code loads team-brain.json → answers question drawing on Dev A's knowledge

### Stage 4 (SQLite + MCP)
- `xcodebuild test` — all existing tests pass against SQLite backend
- Manual: capture → quit → relaunch → snippet visible (persistence across launch)
- `claude "what Swift concurrency snippets do I have?"` → returns results via MCP

### Stage 5 (Team scale-up)
- `docker compose up -d` on second machine → snippet from machine A appears in machine B browse within sync interval
- `FROM @alice SEARCH "auth"` returns Alice's shared snippets
