---
status: Accepted
owner: "ueiktyrj@gmail.com"
reviewers: ["Tech Lead"]
updated_at: "2026-09-05"
feature_size: "M"
ticket: "connection-health"
---

# 0002 — Use a structured-concurrency probe loop

- **Status:** Accepted
- **Date:** 2026-09-05
- **Deciders:** Architect (this session) + operator/owner

## Context

`Core/ConnectionProbing` must run the gateway and external probes on a fixed, user-configurable
interval (spec US-03, default 5s / minimum 1s, spec §8) and hand each cycle's results to the
`ConnectionHealthStore`. The scheduling mechanism touches two modules (Core + the Store) and
the app's idle resource-overhead NFR (spec §6: ≤1% CPU, ≤50MB resident).

## Decision drivers

- Idle CPU/memory NFR (spec §6) — the scheduler runs for the app's entire lifetime.
- `.claude/skills/ios-tdd-workflow/SKILL.md` — reducers/use-cases unit-tested with zero mocking.
- Probing must pause during system sleep (spec §6, Measurement column) and resume on wake.

## Considered options

1. **Structured-concurrency `Task` loop** — `while !Task.isCancelled { probe(); try await Task.sleep(interval) }`, started/cancelled via SwiftUI's `.task {}` lifecycle.
2. **`DispatchSourceTimer` (GCD)** — a timer on a background `DispatchQueue`, delivering results via a closure/delegate.
3. **Combine `Timer.publish`** — a `Timer.publish(...).autoconnect()` pipeline feeding the Store.

## Decision outcome

**Chosen:** Option 1 (structured-concurrency `Task` loop). It composes naturally with Swift's
`async`/`await` (the probes themselves are naturally async I/O), needs no dedicated timer
object to leak or double-fire, and tests as a plain `async` function with no framework mock —
matching the repo's zero-mocking test convention more directly than a GCD timer's
cancel-token lifecycle or a Combine scheduler.

## Consequences

**Positive**
- Cancellation is structured (cancelling the `Task` is sufficient — no separate teardown API).
- Testable with `async` unit tests, no framework double/mock needed.
- No new dependency (Combine stays unused, matching the existing `@Observable`-only state
  approach noted in `architecture-map.md`).

**Negative**
- `Task.sleep` is not wall-clock-precise across a system sleep — the probe service must
  explicitly listen for `NSWorkspace` sleep/wake notifications and pause/resume the loop,
  rather than relying on the scheduler to do it implicitly (a GCD timer with `leeway` would
  have the same gap; this is not a GCD-specific loss, but it is an implementation obligation
  the chosen path doesn't hide).

**Neutral**
- Switching to a GCD timer later is a contained rewrite inside `Core/ConnectionProbing` — it
  doesn't touch the Store's `Intent` surface, since the Store only ever sees delivered results.

## Links

- Spec: [[../spec.md]] §6, US-03
- SAD: [[../sad.md]] §4
