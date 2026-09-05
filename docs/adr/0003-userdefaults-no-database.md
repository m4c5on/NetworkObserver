---
status: Accepted
owner: "Architect"
reviewers: []
updated_at: "2026-09-05"
feature_size: "N/A — foundational (repo-level)"
ticket: "N/A"
---

# 0003 — Store settings in UserDefaults; no database or migration tool

- **Status:** Accepted
- **Date:** 2026-09-05
- **Deciders:** Architect + Maksym (survey greenfield session)

## Context

`docs/idea-brief.md` §5 explicitly excludes historical graphs/trends over days or weeks from v1 —
the app shows current state only. The only persisted data identified so far is user-configurable
settings (probe interval, external host). The default Xcode template shipped with a SwiftData model
(`Item.swift`) that has no relation to this product. This decision fixes the persistence approach
before scaffolding.

## Decision drivers

- v1 scope has no historical data to store (idea-brief §5) — only a handful of settings values.
- SwiftData/Core Data/SQLite bring schema and migration concerns disproportionate to "a few
  key-value settings."
- Avoiding a database now keeps the scaffold's migration-tooling task inapplicable, simplifying the
  skeleton.

## Considered options

1. **`UserDefaults` via `@AppStorage`** — built-in macOS key-value store, no schema, no migrations.
2. **SwiftData** (already present in the template) — full persistence framework with a schema and
   model container, designed for structured/relational data.
3. **A flat JSON/plist file managed by hand** — custom read/write code for settings.

## Decision outcome

**Chosen:** Option 1, `UserDefaults`. It directly matches the shape of the data (a handful of scalar
settings), needs no schema or migration tooling, and is the standard macOS mechanism for this exact
use case. SwiftData is dropped entirely — its scaffolding (`Item.swift`, the `ModelContainer` setup)
is removed rather than repurposed, since v1 has no list of persisted records to manage.

## Consequences

**Positive**
- No migration tooling needed in the skeleton (`scaffold`'s migration task is explicitly dropped).
- Minimal code: `@AppStorage` property wrappers or a thin settings wrapper in `Core/`.

**Negative**
- If v2 ever needs structured/historical data (explicitly out of scope for v1 per idea-brief §5),
  this decision will need revisiting — `UserDefaults` doesn't scale to relational or large data.

**Neutral**
- Revisiting this later (e.g. adding SwiftData back for a history feature) is an additive change,
  not a rewrite of the settings path.

## Links

- Idea brief: [[../idea-brief.md]]
- Architecture map: [[../architecture-map.md]]
- Related ADR: [[0002-mvi-architecture-style]]
