---
id: T2
title: "Spike: verify NWBrowser triggers the Local Network prompt and denial is distinguishable"
layer: "infra"
deps: []
acs: []
files_hint: ["docs/features/connection-health/adr/0003-detect-local-network-permission-via-nwbrowser.md", "Core/ConnectionProbing/"]
owner: "iOS/macOS Engineer"
estimate: "S"
status: "todo"
---

# T2 — Spike: verify NWBrowser triggers the Local Network prompt and denial is distinguishable

## Why

[ADR-0003](../adr/0003-detect-local-network-permission-via-nwbrowser.md) uses a short-lived
`NWBrowser` trigger to both raise the OS's Local Network permission prompt and infer its
grant/denial outcome, but flags both assumptions as unverified (Neutral section). [sad
§11](../sad.md) lists this as a High-severity risk to retire before T7 depends on it for
AC-03/AC-03b.

## What

Write a throwaway `NWBrowser` prototype (not shipped) on a real macOS install. Confirm (a) the
browse raises the same Local Network prompt a direct unicast gateway connection would, and (b)
a post-denial browse failure is distinguishable from an ordinary timeout. Record the outcome in
ADR-0003's Neutral section: either it confirms Option 1 (proceed as designed), or it falls back
to Option 2 (interpret the real gateway probe's failure as permission-denied when
undistinguishable) — note which one T7 should build against.

## Definition of Done

- [ ] Prototype run through both grant and denial paths on a real macOS install
- [ ] ADR-0003 Neutral section updated with the confirmed/refuted outcome
- [ ] If refuted, the fallback (Option 2) is called out explicitly so T7 builds against it

## Notes

This is a research spike, not shippable feature code — no unit tests apply. Blocks T7.
