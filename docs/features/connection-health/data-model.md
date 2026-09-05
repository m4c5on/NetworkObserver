---
status: Draft
owner: "ueiktyrj@gmail.com"
reviewers: []
updated_at: "2026-09-05"
feature_size: "M"
---

# Data model — connection-health

## No schema change

connection-health has **no datastore and no migration tool** (`architecture-map.md`:
`migration_tool: ""`, "no database, no migration tool"). Every quality-goal number, health
state, and probe result lives in in-memory `State` (MVI `Reducer`/`Store`) and is recomputed
every probe cycle — nothing about the diagnosis itself is persisted (spec §3 Non-goals:
no historical graphs/trends).

The only durable value the feature touches is the probe interval (`sad.md` §5 building blocks,
`ConnectionHealthSettings.swift`), stored via `UserDefaults` / `@AppStorage` — a single scalar
key-value pair, not a relational entity, and out of scope for a migration tool:

| Key | Type | Default | Notes |
|---|---|---|---|
| `probeInterval` | `TimeInterval` (seconds) | 5s, enforced minimum 1s (spec §8, AC-05) | Read/written by `ConnectionHealthStore`; validated in `sad.md` §6 Flow 4 before persisting |

No ER diagram, no entity tables, no indexes, and no `.up.sql`/`.down.sql` pair are produced —
there is no schema to version. This is the legitimate no-schema-change outcome the `data-model`
skill documents rather than fabricating a database this feature doesn't need.

## Test fixtures

- No fixtures needed — `probeInterval` is a plain `TimeInterval` set directly in tests via
  `@AppStorage`'s injected `UserDefaults(suiteName:)` test suite, not a factory/builder.
