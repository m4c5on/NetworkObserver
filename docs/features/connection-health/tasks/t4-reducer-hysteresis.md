---
id: T4
title: "ConnectionHealthReducer: AC-08 combination table + AC-04/AC-04b hysteresis"
layer: "domain"
deps: ["T3"]
acs: ["AC-04", "AC-04b", "AC-06", "AC-08"]
files_hint: ["Features/ConnectionHealth/ConnectionHealthReducer.swift"]
owner: "iOS/macOS Engineer"
estimate: "M"
status: "todo"
---

# T4 — ConnectionHealthReducer: AC-08 combination table + AC-04/AC-04b hysteresis

## Why

Derives from [spec AC-04/AC-04b/AC-06/AC-08](../spec.md), [sad §6 Flow 3](../sad.md) and
[ADR-0005](../adr/0005-hysteresis-on-the-combined-state-in-the-reducer.md): the hysteresis is
applied to the already-combined per-cycle candidate, as pure Reducer logic, per the project's
zero-mocking reducer-testing convention.

## What

In `Features/ConnectionHealth/ConnectionHealthReducer.swift`, implement: the AC-08 gateway x
external combination table (100ms threshold for the gateway ok/slow split, per the §4 config
decision); a 3-entry history window of combined candidates; and the transition rule that only
switches the displayed state once all 3 recent candidates agree, in either direction, resetting
the count on any mid-streak flip.

## Definition of Done

- [ ] Unit tests cover all 9 AC-08 gateway x external combinations
- [ ] Unit tests cover the AC-06 100ms threshold mapping (gateway ok vs slow)
- [ ] Unit tests cover AC-04 (a single worse blip does not flip the state)
- [ ] Unit tests cover AC-04b (recovery is symmetric — a single better blip does not flip early)
- [ ] Unit tests cover a mid-streak candidate flip resetting the consecutive count
- [ ] lint + vet clean

## Notes

Zero mocking — this is a pure function over `State` and `Intent` per
`.claude/skills/ios-tdd-workflow/SKILL.md`. Shares no file with any other task.
