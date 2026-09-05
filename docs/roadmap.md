---
status: living
updated_at: "2026-09-05"
---

# Roadmap — NetworkObserver

> **A decomposition, not a promise.** The overall idea broken into incremental steps: what each
> step is, where it comes from, how big it is — or that nobody has looked at it yet — and in which
> order, and parallel lanes, we walk them. **No dates** (except shipped history), **no scores** —
> order is the prioritization. The *solution* for any step lives in its `docs/features/<slug>/`
> spec, not here.

## Destination

The operator can glance at the macOS status bar and immediately know whether an active connection
problem is on their own local network or out on the internet — without opening any other tool.

## Steps

| # | Step | Source | Size | Status |
|---|---|---|:---:|---|
| 1 | Greenfield skeleton (project scaffold) | `architecture-map.md` (mode: greenfield-bootstrap) | XS | idea |
| 2 | connection-health | `idea-brief.md §7`, `docs/features/connection-health/spec.md` | M | spec'd |

## Not yet specified

_None — every step is sized._

## Out of scope

- Per-app bandwidth/traffic breakdown — not the chosen metric; already covered by other menu-bar tools (`idea-brief.md §5`).
- Packet capture / deep traffic inspection — different access level and complexity than a lightweight indicator (`idea-brief.md §5`).
- Historical graphs/trends — v1 shows current state only (`idea-brief.md §5`).
- Push notifications / external alerting — v1 is a local visual indicator only (`idea-brief.md §5`).
- App Store distribution — the diagnostic probes need permissions the sandbox restricts (`idea-brief.md §5`).

## Open decisions

_None open at the roadmap level — the remaining open questions (second external host fallback,
default probe interval/floor, minimum macOS version, colorblind-safe fallback shape) are scoped to
the `connection-health` feature itself and are tracked in `docs/features/connection-health/spec.md §8`,
due before that feature's `/sdd:design` pass._

## Decisions so far

- Minimal macOS menu-bar app, distributed outside the App Store, with automatic gateway-vs-external
  root-cause diagnosis as the headline feature → [`docs/idea-brief.md §7`](idea-brief.md)
- Swift 5 + SwiftUI (`MenuBarExtra`), MVI architecture, `UserDefaults` settings, no database →
  [`docs/architecture-map.md`](architecture-map.md)

## Dependency graph

```mermaid
flowchart LR
  s1["1 · Scaffold"] -->|no Core/ or Features/ folders exist yet to build the feature into| s2["2 · connection-health"]
```

## Execution path

| Wave | Steps | Zone per step (why parallel-safe) | Unlocks |
|:---:|---|---|---|
| 1 | 1 | whole repo tree (new) | 2 |
| 2 | 2 | `NetworkObservation/Core/`, `NetworkObservation/Features/ConnectionHealth/` (new) | — |

Single lane throughout — with only two steps and step 2 entirely dependent on step 1, there is
nothing to run in parallel worktrees yet.

## Shipped

| Step | Shipped | Link |
|---|---|---|
