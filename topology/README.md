# Topology

Service map and data flow contracts for Mnemos. Updated as new services and async patterns are introduced.

## Current State (MVP)

```
[Overlay UI] → [KnowledgeStore (local JSON)] → [DailyLog]
```

All components are in-process. No external services.

## Data Model

### KnowledgeSnippet
| Field       | Type     | Description                        |
|-------------|----------|------------------------------------|
| id          | UUID     | Unique identifier                  |
| content     | String   | The knowledge text                 |
| tags        | [String] | Optional user-applied tags         |
| source      | String   | App context where captured (future)|
| capturedAt  | Date     | Timestamp of capture               |
| expiresAt   | Date     | capturedAt + 7 days (ephemeral)    |

### DailyLog
| Field | Type               | Description            |
|-------|--------------------|------------------------|
| date  | Date (YYYY-MM-DD)  | The calendar day       |
| items | [KnowledgeSnippet] | All snippets that day  |

## Future Services (Planned)
- `SkillsCompiler` — transforms daily logs into executable skill definitions
- `SyncService` — cloud sync, requires auth layer
- `KafkaProducer` — async event stream for multi-agent consumption (post-MVP)

## Async Contracts (Reserved)
If Kafka is introduced, each `KnowledgeSnippet` maps to a `knowledge.captured` event on topic `mnemos.snippets`.
