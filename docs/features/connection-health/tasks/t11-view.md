---
id: T11
title: "ConnectionHealthView: status-bar icon + breakdown popover + settings UI"
layer: "ui"
deps: ["T10"]
acs: ["AC-01", "AC-02", "AC-03", "AC-03b", "AC-05", "AC-06", "AC-07"]
files_hint: ["Features/ConnectionHealth/ConnectionHealthView.swift"]
owner: "iOS/macOS Engineer"
estimate: "M"
status: "todo"
---

# T11 — ConnectionHealthView: status-bar icon + breakdown popover + settings UI

## Why

Derives from [spec US-01/US-02/US-03](../spec.md), [sad §6 Flows 1/2/4](../sad.md). No existing
component to reuse — `architecture-map.md` §Frontend records this as the first screen in the
repo, built from native SwiftUI controls only (no design-system inventory yet).

## What

In `Features/ConnectionHealth/ConnectionHealthView.swift`, implement the `MenuBarExtra` status
icon rendering a colorblind-safe color per `State.healthState` (good/degraded/unreachable/
permission-needed — visibly distinct from no-network, AC-07); the click-through popover showing
the gateway/external breakdown separately (AC-02); the permission-needed explanatory text
directing to System Settings after a denial (AC-03b); and the settings control for the probe
interval, surfacing `State.errorMessage` when a rejected value is entered (AC-05).

## Definition of Done

- [ ] UI tests confirm each of the five states (good/degraded/unreachable/permission-needed/
      no-network) renders a visibly distinct indicator
- [ ] UI tests confirm the popover shows the gateway and external results separately (AC-02)
- [ ] UI tests confirm an out-of-range interval entry surfaces the validation message (AC-05)
- [ ] lint + vet clean

## Notes

Becomes the closest UI precedent for later screens (`architecture-map.md` §Frontend) — keep it
composable so a second feature can reuse its patterns rather than reinventing them.
