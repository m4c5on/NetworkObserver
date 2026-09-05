---
id: T9
title: "ConnectionHealthSettings: probe interval persistence + validation"
layer: "infra"
deps: ["T3"]
acs: ["AC-05"]
files_hint: ["Core/Settings/ConnectionHealthSettings.swift"]
owner: "iOS/macOS Engineer"
estimate: "S"
status: "todo"
---

# T9 — ConnectionHealthSettings: probe interval persistence + validation

## Why

Derives from [spec AC-05](../spec.md), [sad §6 Flow 4](../sad.md) and the §4 config decision
(5s default / 1s enforced minimum, no enforced maximum).

## What

In `Core/Settings/ConnectionHealthSettings.swift`, implement the `probeInterval` `@AppStorage`
key (default 5s) with validation: a value at or above the 1s minimum persists; a value below it
is rejected and the previous valid interval stays in effect.

## Definition of Done

- [ ] Unit tests confirm a value at/above 1s persists
- [ ] Unit tests confirm a value below 1s is rejected and the prior valid interval is retained
- [ ] lint + vet clean

## Notes

Test fixtures use an injected `UserDefaults(suiteName:)` test suite, per `data-model.md` — no
factory/builder needed.
