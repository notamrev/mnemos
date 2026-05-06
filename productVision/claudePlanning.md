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

---

## Current State

| Layer | State | Format |
|---|---|---|
| Capture UI | ✅ Shipped | Manual text + tags |
| Browse UI | 🔄 In Progress (Epic #4) | Day-grouped list, tag filter |
| Storage | ✅ Shipped | Flat JSON, 7-day rolling |
| AI integration | ❌ None | — |
| Auto-capture | ❌ None | — |
| Team sync | ❌ None | — |

---

## Architecture Evolution

```
TODAY
  [macOS Overlay] ──► [KnowledgeStore] ──► [~/Mnemos/YYYY-MM-DD.json]

PHASE 2
  [macOS Overlay] ──► [KnowledgeStore] ──► [SQLite local DB]
                                            (FTS5 + vector via sqlite-vec)

PHASE 3 (AI)
  [macOS Overlay] ──► [KnowledgeStore] ──► [SQLite]
  [Claude Code]   ──► [mnemos-mcp]     ──► [SQLite]  (MCP stdio server)
  [Claude API]    ──►  in-app query UI  ──► [SQLite]

PHASE 4 (Auto-capture)
  [VS Code Ext]   ──► [Mnemos daemon (HTTP)]  ──► [SQLite]
  [macOS Overlay] ──► [Session mode + notifications]

PHASE 5 (Team)
  [each dev SQLite] ──► [mnemos-sync] ──► [PostgreSQL + pgvector]
                                          (Docker Compose, on-prem or cloud)
  [Team query UI] ──► [mnemos-sql / NL query] ──► [PostgreSQL]
  [mnemos-mcp]    ──► [local + team brain]
```

---

## Phase 1 — Complete Current MVP
**Goal:** Finish Epic #4 (browse), close remaining open issues. No new features.

**Issues to close:**
- #35 Search bar (filter by content substring)
- #36 Empty state for browse view
- #37 Tests for browse & review
- #29 TextEditor focus bug fix
- #30 DEVELOPMENT_TEAM in project.yml

**Output:** A polished, fully-tested single-user overlay with manual capture, tag-filtered browse, and content search.

---

## Phase 2 — Storage Foundation (Local DB)
**Goal:** Replace flat JSON files with SQLite. Add FTS and vector storage. No UX change.

### Why SQLite first
- Zero friction — embedded in the Swift app, no Docker, no daemon
- FTS5 extension enables full-text search (needed for Phase 3 query)
- `sqlite-vec` extension adds vector column for embeddings (semantic search)
- Data migration is a one-time import on first launch
- Team layer (Phase 5) will use PostgreSQL — same SQL dialect, easy port

### Schema
```sql
CREATE TABLE snippets (
  id          TEXT PRIMARY KEY,          -- UUID string
  content     TEXT NOT NULL,
  tags        TEXT NOT NULL,             -- JSON array ["swift","ios"]
  source      TEXT NOT NULL DEFAULT 'manual',  -- 'manual' | 'vscode' | 'terminal' | 'clipboard' | 'screen'
  captured_at INTEGER NOT NULL,          -- Unix timestamp
  expires_at  INTEGER NOT NULL,
  metadata    TEXT                       -- JSON blob for source-specific extras
);

CREATE VIRTUAL TABLE snippets_fts USING fts5(content, tags, content='snippets', content_rowid='rowid');

-- Added when sqlite-vec is available:
CREATE VIRTUAL TABLE snippet_embeddings USING vec0(
  snippet_id TEXT PRIMARY KEY,
  embedding  FLOAT[1536]                -- Claude embed-v1 dim
);
```

### Retention
- **Local brain**: 7 days (same as today, purged on launch)
- **Team brain** (Phase 5): configurable (default 7d, admin can extend to 30d / 90d / indefinite)

### New/changed files
- `Mnemos/Storage/KnowledgeDatabase.swift` — SQLite wrapper (using `SQLite.swift` or raw `libsqlite3`)
- `Mnemos/Storage/KnowledgeStore.swift` — swap file I/O for DB calls, keep same public API (`save(_:)`, `fetchAll()`, `fetchToday()`, `purgeExpired()`)
- `Mnemos/Models/KnowledgeSnippet.swift` — add `source: SnippetSource` field (enum, default `.manual`)
- `Mnemos/Models/SnippetSource.swift` — new enum: `manual | vscode | terminal | clipboard | screen`
- `MnemosTests/KnowledgeDatabaseTests.swift` — SQL round-trip, FTS, migration
- `project.yml` — add sqlite-vec SPM package

### Migration
On first launch after upgrade: load all existing JSON files → insert into SQLite → rename JSON files to `.migrated` → purge on second launch.

---

## Phase 3 — AI Integration (MCP + Claude API)
**Goal:** Let Claude Code query the local brain via MCP. Let in-app users query with natural language using their own Claude API key.

### 3A — mnemos-mcp (MCP stdio server)
A standalone Swift or Go binary that implements the MCP protocol over stdio. Claude Code adds it to `~/.claude/settings.json` as an MCP server.

**Exposed tools:**
```
search_brain(query: string, limit?: number) → snippet[]
  -- FTS + optional semantic reranking

get_snippets_for_file(file_path: string) → snippet[]
  -- Returns snippets where metadata.file_path matches

add_snippet(content: string, tags: string[]) → snippet
  -- Capture from Claude Code without opening overlay

list_tags(prefix?: string) → string[]
  -- All tags in local brain

query_team(query: string, member_id?: string) → snippet[]
  -- Phase 5: fan out to team PostgreSQL
```

**Binary location:** `~/.mnemos/mnemos-mcp` (installed via `brew install` or app bundle)

**New files:**
- `mnemos-mcp/` — new Swift Package (CLI target)
- `mnemos-mcp/Sources/main.swift` — MCP stdio loop
- `mnemos-mcp/Sources/BrainClient.swift` — reads local SQLite
- `mnemos-mcp/Sources/Tools/` — one file per tool

### 3B — Claude API key + in-app query
- API key stored in macOS Keychain (never on disk)
- New "Ask" mode in overlay (third tab: Capture | Browse | Ask)
- User types natural language question → app calls Claude Haiku with relevant snippets as context → answer shown inline
- Relevant snippets fetched via FTS + optional embedding similarity

**New/changed files:**
- `Mnemos/Overlay/AskView.swift` — new tab
- `Mnemos/Overlay/AskViewModel.swift` — Anthropic SDK calls
- `Mnemos/Services/ClaudeService.swift` — API key read from Keychain, request builder
- `Mnemos/Services/KeychainService.swift` — read/write API key
- `Mnemos/Overlay/OverlayViewModel.swift` — add `.ask` mode

---

## Phase 4 — Automatic Capture
**Goal:** Add a Manual / Auto toggle. In Auto mode, a VS Code extension feeds events to a local Mnemos daemon. Session mode with timer and notifications.

### UX: Manual / Auto toggle
- Toggle in MenuBarView (or overlay header)
- **Manual**: current behaviour — user explicitly opens overlay and types
- **Auto**: Mnemos daemon runs, VS Code extension sends events, smart filtering stores relevant snippets, notifications keep user informed

### 4A — Local Mnemos Daemon
A lightweight HTTP server (localhost only, port 40842) that accepts capture events from VS Code / terminal hooks.

```
POST /capture
{
  "source": "vscode",
  "content": "Opened AuthService.swift in mnemos project",
  "tags": ["swift", "auth"],
  "metadata": { "file_path": "/path/to/file", "project": "mnemos" }
}
```

Daemon started automatically when Auto mode is toggled on. Runs as a background NSApplication service or launchd agent.

**New files:**
- `MnemosDaemon/` — new Swift Package
- `MnemosDaemon/Sources/CaptureServer.swift` — lightweight HTTP server (NIO or URLSession-based)
- `MnemosDaemon/Sources/FilterEngine.swift` — deduplication + relevance scoring

### 4B — VS Code Extension (MVP auto-capture)
TypeScript extension in `extensions/vscode/`.

**Captures (with user consent, toggled per type):**
- File open/save: `"Opened AuthService.swift — modified 3 functions"`
- Terminal commands in VS Code integrated terminal (significant commands only)
- Errors in Problems panel: `"Error in AuthService.swift: cannot find type 'Token'"`
- Git operations: `"Committed feat(auth): add token refresh — 3 files changed"`

**Sends:** POST to `localhost:40842/capture`
**Settings:** VS Code settings JSON for toggle, filter rules, tag prefix

**Key files:**
- `extensions/vscode/src/extension.ts` — activation, event listeners
- `extensions/vscode/src/captureClient.ts` — HTTP client to daemon
- `extensions/vscode/src/filterEngine.ts` — what's worth capturing
- `extensions/vscode/package.json` — VS Code extension manifest

### 4C — Session Mode + Notifications
- Session: user sets timer (default 25min, Pomodoro-style)
- macOS `UserNotifications` framework shows periodic "Mnemos is tracking: 3 snippets captured"
- End-of-session summary notification with count + top tags captured
- "What's being tracked" live feed panel in overlay

**New/changed files:**
- `Mnemos/Session/SessionManager.swift` — timer, state (idle | recording | paused)
- `Mnemos/Session/SessionViewModel.swift` — UI binding
- `Mnemos/Overlay/SessionView.swift` — session panel
- `Mnemos/Services/NotificationService.swift` — UserNotifications wrapper

### Future auto-capture sources (post-MVP)
- Terminal shell hooks (zsh/fish): separate install step, same daemon pattern
- JetBrains plugin: same architecture as VS Code extension
- Clipboard monitor: `NSPasteboard` polling, user-toggled
- Screen OCR: `Vision` framework, periodic screenshot, high privacy gate

---

## Phase 5 — Team Brain (Multi-User + Team Sync)
**Goal:** Each developer's local SQLite syncs shared snippets to a team PostgreSQL. Team members can query each other's brains.

### Team identity model
```sql
-- Team PostgreSQL schema
CREATE TABLE members (
  id          UUID PRIMARY KEY,
  name        TEXT,
  email       TEXT UNIQUE,
  team_id     UUID NOT NULL
);

CREATE TABLE snippets (
  id          UUID PRIMARY KEY,
  member_id   UUID REFERENCES members(id),
  content     TEXT NOT NULL,
  tags        JSONB NOT NULL,
  source      TEXT NOT NULL,
  captured_at TIMESTAMPTZ NOT NULL,
  expires_at  TIMESTAMPTZ,            -- NULL = indefinite
  is_shared   BOOLEAN DEFAULT FALSE,  -- privacy gate
  embedding   VECTOR(1536),           -- pgvector
  metadata    JSONB
);

CREATE INDEX ON snippets USING ivfflat (embedding vector_cosine_ops);
CREATE INDEX ON snippets USING GIN (tags);
```

### Sync protocol
- **Push**: local daemon POSTs new shared snippets to team server on save
- **Pull**: periodic background sync (configurable interval)
- **Conflict**: last-write-wins per snippet ID (no CRDTs needed at this scale)
- **Privacy**: only `is_shared = TRUE` snippets leave the device

### Team server
- Single Go binary (`mnemos-server`)
- REST API: `POST /snippets`, `GET /snippets/search`, `GET /members`
- `docker-compose.yml`: mnemos-server + PostgreSQL + pgvector
- Spun up with `docker compose up -d` — zero config for standard use

**New subdirectory:** `server/` (Go module)
- `server/cmd/mnemos-server/main.go`
- `server/internal/api/` — REST handlers
- `server/internal/store/` — PostgreSQL queries (pgx)
- `server/internal/sync/` — push/pull logic
- `docker-compose.yml` — at repo root

### mnemos-sql query language
Thin SQL dialect over team PostgreSQL:
```sql
FROM @alice SEARCH "authentication token refresh"
FROM @team TAGGED "swift" SINCE 7d
FROM @team WHERE content CONTAINS "race condition" LIMIT 10
FROM @me RECENT 20
```

Translates to: `SELECT * FROM snippets JOIN members ON ... WHERE ...`

Parser: simple PEG grammar (`FROM @<member|team|me> <verb> ...`). Initial implementation is a regex-based preprocessor that emits real SQL.

### Retention (team)
- Default: 7 days (matches local)
- Admin-configurable: 30d / 90d / indefinite
- Set via `docker-compose.yml` env var `MNEMOS_RETENTION_DAYS=90` or API

---

## Epics to Create (post-MVP)

| Epic | Title | Unlock After |
|---|---|---|
| #7 | Storage: SQLite migration + FTS | Phase 1 complete |
| #8 | AI: mnemos-mcp stdio server | Phase 2 complete |
| #9 | AI: Claude API key + Ask tab | Phase 2 complete |
| #10 | Auto-capture: Mnemos daemon + VS Code extension MVP | Phase 3 complete |
| #11 | Auto-capture: Session mode + notifications | Epic #10 |
| #12 | Team: sync server + Docker Compose | Phase 4 complete |
| #13 | Team: mnemos-sql query layer | Epic #12 |
| #14 | Auto-capture: terminal, JetBrains, clipboard, screen | Epic #12 |

---

## Critical Files (Current → Modified)

| File | Change |
|---|---|
| `Mnemos/Storage/KnowledgeStore.swift` | Swap JSON I/O for SQLite via KnowledgeDatabase |
| `Mnemos/Models/KnowledgeSnippet.swift` | Add `source: SnippetSource` field |
| `Mnemos/Overlay/OverlayView.swift` | Add Ask tab (Phase 3) |
| `Mnemos/Overlay/OverlayViewModel.swift` | Add `.ask` mode (Phase 3) |
| `Mnemos/App/MenuBarView.swift` | Add Manual/Auto toggle (Phase 4) |
| `project.yml` | Add SQLite SPM dep (Phase 2), daemon target (Phase 4) |
| `docker-compose.yml` | New file — team server (Phase 5) |

---

## Verification

### Phase 2
- `xcodebuild test` — all existing tests pass against SQLite backend
- Manual: capture snippet → quit app → relaunch → snippet visible in browse

### Phase 3 (MCP)
- Add mnemos-mcp to Claude Code settings → `claude "what Swift concurrency snippets do I have?"` returns results
- API key stored: verify no file on disk, verify Keychain entry exists

### Phase 4 (Auto-capture)
- Toggle Auto → open a file in VS Code → overlay shows new snippet within 5s
- Session timer counts down → macOS notification fires at end

### Phase 5 (Team)
- `docker compose up -d` on second machine → snippet from machine A appears in machine B browse within sync interval
- `FROM @alice SEARCH "auth"` returns Alice's shared snippets
