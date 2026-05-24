# Mnemos Product Roadmap — Local Brain → Team Brain

## Context

Mnemos is currently a manual-input, single-user, macOS overlay with ephemeral JSON storage (7-day rolling window). The product vision is to evolve it into a **team knowledge network**: each developer has a private local brain, teams can query each other's shared brains in English or mnemos-sql, and AI (Claude) can access the brain directly via an API key or MCP server. Data input grows from manual-only to include automatic capture from VS Code, terminal, screen, and clipboard.

This plan defines the phases, technology decisions, and epics required to reach that end state without breaking the current MVP workflow.

---

## Guiding Principles

- **Local-first, zero friction** — individual brain requires no server, no Docker, no account
- **Cloud-agnostic team layer** — on-premise or client cloud; Podman Compose as the deployment primitive (Podman preferred over Docker — rootless, daemon-free)
- **Privacy by default** — all automatic capture is opt-in; snippets are private unless explicitly shared
- **Monolithic-first** — no microservices split until a boundary forces it
- **macOS native stays** — overlay remains Swift/SwiftUI; new components (MCP server, VS Code extension, sync server) are separate binaries/packages
- **No throwaway code** — each stage must extend the previous one, never replace it; temporary compatibility shims are banned
- **Beta-first SDLC** — ship the smallest working thing to real users before building infrastructure; validate before scaling

---

## Current State

| Layer | State | Format |
|---|---|---|
| Capture UI | ✅ Shipped | Manual text + tags |
| Browse UI | ✅ Shipped | Day-grouped list, tag filter, search |
| Storage | ✅ Shipped | Flat JSON, 7-day rolling |
| Skills Compiler | ✅ Shipped | group snippets by tag → skills.json, 5s auto-compile |
| VS Code Auto-capture | ✅ Shipped | file open/save → POST localhost:40842; terminal opt-in |
| SQLite storage | 🔄 In Progress (Epic #64) | embedded, FTS5, replaces JSON |
| MCP server | 🔄 In Progress (Epic #65) | stdio server for Claude Code queries |
| Team sync | ❌ Not started (Epic #66) | PostgreSQL + Podman, after Stage 3 |

---

## Revised Roadmap — Beta-First, No Throwaway Code

Each stage extends the previous one. Nothing gets removed or replaced.

```
Stage 1: MVP + Skills Compiler          ✅ Done
Stage 2: VS Code Auto-capture           ✅ Done
Stage 3: SQLite + MCP server            ← NOW
Stage 4: Team Brain (PostgreSQL/Podman) next
```

**Why this order:**
- Stage 3 (SQLite) is the permanent storage layer — it extends the existing KnowledgeStore API, nothing is ripped out
- Stage 3 (MCP) reads from SQLite and exposes the brain to Claude Code — the permanent sharing mechanism
- Stage 4 adds a PostgreSQL sync on top of the same MCP interface — no code deleted, just extended
- Git-based sharing was considered and **rejected** to avoid a throwaway code path

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

## Stage 3 — SQLite + MCP Server
**Goal:** Replace flat JSON with embedded SQLite (permanent storage). Build the mnemos-mcp stdio server so Claude Code can query the brain in real-time. No throwaway code — this is the permanent local stack that Stage 4 builds on top of.

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

**Issues:**
- #67 feat: KnowledgeDatabase — SQLite wrapper with FTS5 (Ready)
- #68 feat: KnowledgeStore — swap JSON I/O for SQLite (Backlog)
- #69 feat: JSON→SQLite migration on first launch (Backlog)
- #70 test: SQLite round-trip, FTS, migration, purge (Backlog)
- #65 Epic: MCP Server (mnemos-mcp) (Backlog)

---

## Stage 4 — Team Brain
**Goal:** PostgreSQL + pgvector team sync. Multiple developers share a live queryable brain. Uses Podman as the container runtime (`podman compose up -d`). Extends the Stage 3 MCP interface — no code removed, just new tools added.

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

**Container runtime:** Podman (rootless, daemon-free). `docker-compose.yml` is Podman Compose-compatible.
Local test: `podman machine start && podman compose up -d`

**Issues (to create after Stage 3 complete):**
- Epic #66: Team Brain — PostgreSQL + Podman
- Sub-epics: Go sync server, mnemos-sql query layer, terminal/JetBrains/clipboard auto-capture

---

## Epics Map

| Epic | Title | Stage | Status |
|---|---|---|---|
| #1 | Overlay Shell | 1 | ✅ Done |
| #2 | Knowledge Capture | 1 | ✅ Done |
| #3 | Ephemeral Storage | 1 | ✅ Done |
| #4 | Browse & Review | 1 | ✅ Done |
| #5 | Skills Compiler | 1 | ✅ Done |
| #6 | App Polish & Distribution | 1 | ✅ Done |
| #51 | VS Code Auto-capture | 2 | ✅ Done |
| #64 | SQLite Migration + FTS | 3 | 🔄 In Progress |
| #65 | MCP Server (mnemos-mcp) | 3 | 📋 Planned |
| #66 | Team Brain (PostgreSQL + Podman) | 4 | 🔒 Locked (after Stage 3) |

---

## Critical Files (Across All Stages)

| File | Change | Stage |
|---|---|---|
| `Mnemos/SkillsCompiler/SkillsCompiler.swift` | New: group by tag, emit skills.json | 1 ✅ |
| `Mnemos/Capture/CaptureServer.swift` | New: localhost HTTP receiver | 2 ✅ |
| `extensions/vscode/src/extension.ts` | New: VS Code extension | 2 ✅ |
| `Mnemos/Storage/KnowledgeDatabase.swift` | New: SQLite wrapper + FTS5 | 3 |
| `Mnemos/Storage/KnowledgeStore.swift` | Swap JSON I/O for SQLite | 3 |
| `mnemos-mcp/Sources/main.swift` | New: MCP stdio server | 3 |
| `docker-compose.yml` | New: team server (Podman-compatible) | 4 |

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
