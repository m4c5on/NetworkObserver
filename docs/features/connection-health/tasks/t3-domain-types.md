---
id: T3
title: "Define ConnectionHealthDomain (State / Intent / Effect types)"
layer: "domain"
deps: []
acs: ["AC-01", "AC-07", "AC-08"]
files_hint: ["Features/ConnectionHealth/ConnectionHealthDomain.swift"]
owner: "iOS/macOS Engineer"
estimate: "S"
status: "todo"
---

# T3 — Define ConnectionHealthDomain (State / Intent / Effect types)

## Why

Every other task ([sad §5](../sad.md)) depends on the shared `State`/`Intent`/`Effect` shapes
per the project's MVI convention (`.claude/skills/ios-MVI-architecture/SKILL.md`). This task
lays down that vocabulary once, so the Reducer, Store, probes and View all speak the same types.

## What

In `Features/ConnectionHealth/ConnectionHealthDomain.swift`, define: the per-probe result enum
(`ok`/`slow`/`failing`, [spec AC-08](../spec.md)); the overall health-state enum
(`good`/`degraded`/`unreachable`/`permissionNeeded`/`noNetwork`, covering [AC-01](../spec.md) and
[AC-07](../spec.md)); the `Intent` cases the Reducer will handle (`.cycleCompleted`,
`.intervalChanged`, `.permissionResolved`, `.noNetworkDetected`); and the `State` struct holding
the current health state, the gateway/external breakdown, and the probe interval.

## Definition of Done

- [ ] Unit tests confirm the State enum exhaustively models good/degraded/unreachable/
      permission-needed/no-network
- [ ] Unit tests confirm the per-probe result enum models ok/slow/failing
- [ ] lint + vet clean

## Notes

Pure types only — no logic here (that's T4). Every downstream task's `files_hint` implies this
file as a read-only import.
