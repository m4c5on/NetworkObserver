---
id: T1
title: "Spike: verify unprivileged ICMP ping-socket viability on macOS"
layer: "infra"
deps: []
acs: []
files_hint: ["docs/features/connection-health/adr/0004-icmp-gateway-tls-handshake-external-probes.md", "Core/ConnectionProbing/"]
owner: "iOS/macOS Engineer"
estimate: "S"
status: "todo"
---

# T1 — Spike: verify unprivileged ICMP ping-socket viability on macOS

## Why

[ADR-0004](../adr/0004-icmp-gateway-tls-handshake-external-probes.md) chose an unprivileged
`SOCK_DGRAM`/`IPPROTO_ICMP` ping-socket for the gateway probe but flags it as an unverified
community pattern (Neutral section). [sad §11](../sad.md) lists this as a High-severity risk to
retire before T5 is built on top of it.

## What

Write a throwaway ICMP echo prototype (not shipped) against a real gateway on an unsandboxed,
non-App-Store macOS build. Confirm whether an unprivileged ping-socket round-trips without
elevated privileges. Record the outcome directly in ADR-0004's Neutral section: either it
confirms Option 1 (proceed as designed), or it falls back to ADR-0004 Option 2 (TCP-connect to
the gateway) — either way, note the decision so T5 knows which mechanism to build.

## Definition of Done

- [ ] Prototype run against a real gateway, result observed and recorded
- [ ] ADR-0004 Neutral section updated with the confirmed/refuted outcome
- [ ] If refuted, the fallback (Option 2) is called out explicitly so T5 builds against it

## Notes

This is a research spike, not shippable feature code — no unit tests apply. Blocks T5.
