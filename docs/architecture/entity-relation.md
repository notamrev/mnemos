# Entity Relationship Diagram

> Last updated by PR #19 — KnowledgeSnippet and DailyLog models

```mermaid
erDiagram
    DAILY_LOG {
        string date PK "YYYY-MM-DD — one log per calendar day"
    }

    KNOWLEDGE_SNIPPET {
        uuid    id          PK  "auto-generated on init"
        string  content         "raw text of the captured knowledge"
        array   tags            "user-supplied string labels"
        date    capturedAt      "timestamp of capture"
        date    expiresAt       "capturedAt + 7 days (rolling window)"
    }

    DAILY_LOG ||--o{ KNOWLEDGE_SNIPPET : "contains"
```

## Storage model (v1)
- Persistence: flat JSON files, one file per `DAILY_LOG` date key
- Location: `~/Library/Application Support/Mnemos/logs/YYYY-MM-DD.json`
- Retention: files older than 7 days are pruned on next launch
- No cloud sync in v1 — local only

## Future entities (post-MVP)
| Entity | Purpose |
|--------|---------|
| `Tag` | Normalised tag with colour + description |
| `Skill` | Executable AI prompt derived from a set of snippets |
| `SyncRecord` | Cloud sync manifest for multi-device support |
