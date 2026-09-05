# Tracker — connection-health

> Status of every task in the epic. `implement` updates `done` as it commits each task.
> States: `todo` · `in_progress` · `blocked` · `review` · `done`.

| # | Task | Layer | Owner | Estimate | Blocked by | Status |
|---|---|---|---|---|---|---|
| T1 | Spike: ICMP ping-socket viability | infra | iOS/macOS Engineer | S | — | done |
| T2 | Spike: NWBrowser permission trigger | infra | iOS/macOS Engineer | S | — | done (partial — see ADR-0003 Neutral) |
| T3 | Domain types (State/Intent/Effect) | domain | iOS/macOS Engineer | S | — | done |
| T4 | Reducer (AC-08 combination + hysteresis) | domain | iOS/macOS Engineer | M | T3 | done |
| T5 | GatewayProbe (ICMP) | infra | iOS/macOS Engineer | M | T1, T3 | done |
| T6 | ExternalHostProbe (TCP/TLS) | infra | iOS/macOS Engineer | S | T3 | done |
| T7 | LocalNetworkPermission | infra | iOS/macOS Engineer | M | T2, T3 | done |
| T8 | No-network detection | infra | iOS/macOS Engineer | S | T3 | done |
| T9 | Settings (probe interval) | infra | iOS/macOS Engineer | S | T3 | done |
| T10 | Store orchestration + sleep/wake | app | iOS/macOS Engineer | L | T4, T5, T6, T7, T8, T9 | done |
| T11 | View (status bar + popover) | ui | iOS/macOS Engineer | M | T10 | done |
| T12 | App wiring (MenuBarExtra + DI) | wiring | iOS/macOS Engineer | S | T11 | done (needs your manual smoke run — see below) |
| T13 | NFR instrumentation (os_log) | tests | iOS/macOS Engineer | S | T10 | todo |

**Total:** 13 tasks, ~6–7 person-days (M-size feature, 1–2 sprints per `.size`).
