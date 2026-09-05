---
status: Draft
owner: "ueiktyrj@gmail.com"
reviewers: ["iOS/macOS Engineer", "Tech Lead"]
updated_at: "2026-09-05"
feature_size: "M"
---

# Test plan — connection-health

A menu-bar health indicator that combines a gateway probe and an external-host probe into one
color-coded state (good/degraded/unreachable/permission-needed/no-network), with a 3-consecutive-
cycle hysteresis so a single blip never flips the display.

## Levels

| Level | Scope | Strategy (generic — no tool names) |
|---|---|---|
| Unit | Pure logic: the Reducer's AC-08 combination table, AC-04/AC-04b hysteresis, the settings validator, and the permission/no-network signal derivation. | In-memory, no external dependency. |
| Integration | `GatewayProbe` and `ExternalHostProbe` against a real network dependency they own. | A local ephemeral server spun up per test (a loopback TCP/TLS listener, and a local ICMP-style responder) — never the real gateway or the real `1.1.1.1:443`, so the suite doesn't depend on the machine's actual network or an internet connection. |
| Component | `ConnectionHealthView` exercised in isolation. | Render each of the 5 states and the breakdown popover in a component harness; assert the rendered output, not a live status-bar click. |
| E2E-through-UI | The full status-bar flow driven through the real running app. | A manual smoke checklist run before release — not automated (menu-bar/status-bar items are not reliably drivable by standard UI-automation tooling); see Notes. |
| Load | NFR validation — idle resource overhead, crash-free sessions, and false-positive rate, each measured over a continuous run. | No server, no request rate to drive — the scenario is a fixed-duration soak run instrumented locally and sampled with the OS's own resource monitor (spec §6's own measurement method), not a request-driven load tool. |

## AC coverage

| AC (spec.md §5) | Test name (intent-based) | Level | Expected outcome |
|---|---|---|---|
| AC-01 (happy path) | good gateway + good external latency shows the good-health color | Unit + Component | status bar shows the good-health color and nothing else |
| AC-02 (cross-context) | external failing while gateway ok shows unreachable color, click reveals gateway ok / external failing separately | Integration + Unit + Component | breakdown popover shows the two results separately; status bar shows the unreachable color |
| AC-03 (authorization, not yet requested) | first probe cycle requests Local Network permission and shows the permission-needed state | Unit + Component | permission-needed state (unreachable color + explanatory text), not a silent wrong reading |
| AC-03b (authorization, denied) | a denied permission shows the permission-needed state with System-Settings guidance | Unit + Component | permission-needed state persists, text explains the operator must open System Settings |
| AC-04 (domain invariant) | a single worse-result blip does not flip the displayed state | Unit | state stays at its current (better) level after 1–2 worse cycles |
| AC-04b (domain invariant, recovery) | a single better-result blip does not flip the displayed state early | Unit | state stays at its current (worse) level after 1–2 better cycles |
| AC-05 (error) | an interval below the enforced minimum is rejected | Unit + Component | value rejected, minimum explained, previous valid interval stays in effect |
| AC-06 (happy path) | gateway latency over the 100ms threshold with external still ok shows degraded | Unit + Component | degraded color, visibly distinct from good and unreachable |
| AC-07 (edge case) | no active network interface shows a distinct no-network state | Unit + Component | "no network" state, visibly different from the unreachable color |
| AC-08 (domain invariant) | every gateway x external combination maps to the spec's mapping table | Unit | overall state matches the AC-08 table for all 9 combinations |

## Edge cases / error paths

- Probe timeout (gateway or external unreachable) vs. no active network interface → expected: kept as two distinct states — a timeout reads as degraded/unreachable per AC-08, never as the "no-network" state, and vice versa (AC-07 boundary).
- The app goes to sleep mid-cycle (system suspend) → expected: the probe loop pauses and resumes cleanly on wake, with no missed-cycle counted as a false transition (ADR-0002).
- A candidate result flips before reaching 3 consecutive matching cycles → expected: the consecutive count resets to 0 for the new candidate; no partial transition is ever applied (sad §6 Flow 3).
- The NWBrowser permission trigger's denial failure turns out indistinguishable from an ordinary timeout (if T2's spike falsifies the ADR-0003 assumption) → expected: the ADR-0003 fallback mechanism still yields a distinct permission-needed state, never conflated with a genuine gateway-unreachable reading.

## Test data

- Seed strategy: no entities/fixtures — per `data-model.md`, the only durable value is `probeInterval`, set directly in tests via an injected `UserDefaults(suiteName:)` test suite (no factory/builder).
- Integration dependency: a local ephemeral server per test (a loopback TCP/TLS listener for `ExternalHostProbe`, a local ICMP-style responder for `GatewayProbe`) — never the real gateway or the real `1.1.1.1:443`, and never a mocked probe.
- Cleanup boundary: per-test — each test starts and tears down its own ephemeral listener/responder and its own `UserDefaults` suite, so runs are independent and don't leak state into CI.

## NFR validation (load)

<!-- No numeric NFR here fits a request-rate scenario — each is a resource/stability soak run per -->
<!-- spec §6's own measurement method (local instrumentation + the OS's resource monitor), not a -->
<!-- load tool; the scenarios below are that soak run, described generically. -->

- Status update latency ≤ 250ms (spec §6, QG-3) → scenario: local instrumentation timestamps probe-cycle completion and the moment the status bar's `State` update lands; assert the delta ≤ 250ms across a sample of cycles.
- Detection latency ≤ 3 probe intervals / ≤ 15s at the 5s default (spec §6, QG-4) → scenario: derived from the AC-04 hysteresis unit tests directly (3 cycles x the configured interval); confirmed again during the idle soak run below.
- Idle CPU ≤ 1% average (spec §6, QG-2) → scenario: 1-hour idle run at the default interval, sampled via the OS's resource monitor, assert average ≤ 1%.
- Idle memory ≤ 50MB resident (spec §6, QG-2b) → scenario: same 1-hour idle run, assert resident memory ≤ 50MB.
- Crash-free sessions ≥ 99% (spec §6, QG-5) → scenario: a 7-day continuous run, assert the soak-test log shows ≥99% crash-free sessions.
- False-positive rate ≤ 1 false transition into degraded/unreachable per 24h (spec §6 Accuracy) → scenario: a 24h continuous run under known-good network conditions, assert the soak-test log shows ≤1 false state transition (counted per transition, not per probe cycle).

## CI placement

- On every PR: Unit (Reducer, Settings, permission/no-network signals) and Component (all 5 View states + the breakdown popover) — fast, no network dependency.
- On schedule / pre-release: Integration (GatewayProbe/ExternalHostProbe against the local ephemeral server) and the manual E2E-through-UI smoke checklist; the Load (soak) scenarios run as their own scheduled long-duration jobs (1-hour idle sample, 24h false-positive run, 7-day crash-free run), not on every PR.

## Notes

- **E2E-through-UI stays manual.** This is the repo's first UI feature (no `design-system.md` /
  `screens.md` yet) and a `MenuBarExtra` status item is not reliably drivable by standard
  UI-automation tooling — clicking the actual menu-bar icon from an automated test is fragile.
  The manual pre-release checklist covers: icon color for each of the 5 states, the click-through
  breakdown popover, the settings interval control and its validation message, and the
  System-Settings guidance text after a permission denial.
- Every task in `tasks.json` already names its test in its `dod` — this plan is the AC-level map
  those per-task tests trace back to, not a duplicate spec.
