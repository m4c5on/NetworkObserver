---
id: T7
title: "LocalNetworkPermission: NWBrowser trigger + denial detection"
layer: "infra"
deps: ["T2", "T3"]
acs: ["AC-03", "AC-03b"]
files_hint: ["Core/ConnectionProbing/LocalNetworkPermission.swift"]
owner: "iOS/macOS Engineer"
estimate: "M"
status: "todo"
---

# T7 — LocalNetworkPermission: NWBrowser trigger + denial detection

## Why

Derives from [spec AC-03/AC-03b](../spec.md), [sad §6 Flow 2](../sad.md) and
[ADR-0003](../adr/0003-detect-local-network-permission-via-nwbrowser.md). The exact mechanism is
whatever T2's spike confirmed.

## What

In `Core/ConnectionProbing/LocalNetworkPermission.swift`, implement the first-probe-time
permission check using the mechanism T2 confirmed (an `NWBrowser` trigger, or the fallback of
reading the real gateway probe's failure as denial). Emit a distinct
granted/denied/not-yet-requested signal, kept separate from a genuine gateway-unreachable result.

## Definition of Done

- [ ] Unit tests confirm a granted outcome proceeds to the real probe cycle
- [ ] Unit tests confirm a denied outcome emits the permission-needed signal, distinguishable
      from a probe timeout
- [ ] lint + vet clean

## Notes

Depends on T2's spike result — do not start building the real mechanism before T2 lands.
