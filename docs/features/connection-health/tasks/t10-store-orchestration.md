---
id: T10
title: "ConnectionHealthStore: probe loop orchestration + sleep/wake"
layer: "app"
deps: ["T4", "T5", "T6", "T7", "T8", "T9"]
acs: ["AC-01", "AC-02", "AC-03", "AC-03b", "AC-05", "AC-07", "AC-08"]
files_hint: ["Features/ConnectionHealth/ConnectionHealthStore.swift"]
owner: "iOS/macOS Engineer"
estimate: "L"
status: "todo"
---

# T10 — ConnectionHealthStore: probe loop orchestration + sleep/wake

## Why

Derives from [sad §5/§6](../sad.md) and [ADR-0002](../adr/0002-use-a-structured-concurrency-probe-loop.md):
the Store owns the running probe `Task`, wires the permission check ahead of the first real
cycle, and dispatches results to the Reducer.

## What

In `Features/ConnectionHealth/ConnectionHealthStore.swift`, implement: the structured-concurrency
`Task` loop (`while !Task.isCancelled { ... try await Task.sleep(interval) }`) started/cancelled
via `.task {}`; the first-cycle permission gate (T7) ahead of the real probe cycle (T5+T6); the
no-network check (T8) ahead of that; dispatch of `.intervalChanged` (T9) with rescheduling; and
`NSWorkspace` sleep/wake notification handling to pause/resume the loop (ADR-0002 Negative
consequence).

## Definition of Done

- [ ] Integration tests confirm the permission check runs once before the first real probe cycle
- [ ] Integration tests confirm a probe cycle runs, dispatches `.cycleCompleted` to the Reducer,
      and the interval reschedules on `.intervalChanged`
- [ ] Integration tests confirm the loop pauses on a sleep notification and resumes on wake
- [ ] lint + vet clean

## Notes

Injects T4-T9's services into `Store.init` (never creates them inside the Store), per
`.claude/skills/ios-MVI-architecture/SKILL.md`.
