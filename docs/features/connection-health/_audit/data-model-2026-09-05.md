# Data-model audit — connection-health — 2026-09-05

## Outcome: no schema change (legitimate N/A)

- `architecture-map.md` fixes `migration_tool: ""` and "no database, no migration tool" for this
  repo — connection-health is a single-process macOS menu-bar app with no datastore.
- `sad.md` §2 Constraints and §8 Crosscutting confirm: "No datastore — settings only, persisted
  via `UserDefaults`" and "ID strategy: N/A — no persisted entities with IDs in v1".
- The only durable value is the probe interval, a single `UserDefaults`/`@AppStorage` scalar
  key — not a relational entity, so no table, no migration, no ER diagram.

## Staged migrations

**None.** `docs/features/connection-health/migrations/` was not created — there is nothing to
stage.

## Promote-time convention hint

N/A — no migration tool exists in this repo (`architecture-map.md` §Migrations: "none —
dropped explicitly, see scaffold plan"). `implement` has nothing to promote for this feature.

## Convention deviations

None — `data-model.md` follows the architecture's explicit no-datastore decision; nothing was
imposed.

## Drift findings

None run — drift detection maps domain-layer fields to DB columns; there is no DB to drift
against.

## Self-check (4 mandatory)

| Check | Result |
|---|---|
| Naming matches repo convention | N/A — no migration files |
| Down reversibility | N/A — no migration files |
| FK indexes | N/A — no tables |
| Convention adherence | Pass — matches the repo's explicit "no datastore" decision |

## Open TBDs

None.

## Next stage

Per `.route` (`standard`): `api`'s N/A condition (no contract change) does not automatically
apply here — `api` should be run to confirm whether connection-health exposes any contract
surface at all; if it also finds nothing to derive, it will skip forward to `tasks` on its own
N/A path. Run `/sdd:api connection-health`.
