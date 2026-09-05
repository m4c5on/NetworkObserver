---
id: T5
title: "GatewayProbe: ICMP echo + latency"
layer: "infra"
deps: ["T1", "T3"]
acs: ["AC-06"]
files_hint: ["Core/ConnectionProbing/GatewayProbe.swift"]
owner: "iOS/macOS Engineer"
estimate: "M"
status: "todo"
---

# T5 — GatewayProbe: ICMP echo + latency

## Why

Derives from [ADR-0004](../adr/0004-icmp-gateway-tls-handshake-external-probes.md) (ICMP for the
gateway) and [sad §6 Flow 1](../sad.md). The exact socket mechanism is whatever T1's spike
confirmed.

## What

In `Core/ConnectionProbing/GatewayProbe.swift`, implement a probe against the OS's default-route
gateway that returns reachability + round-trip latency (or a timeout), using the mechanism T1
confirmed (unprivileged ICMP ping-socket, or the TCP-connect fallback).

## Definition of Done

- [ ] Unit/integration tests confirm a successful probe returns a latency value
- [ ] Unit/integration tests confirm a timeout is reported distinctly from a successful-but-slow
      result
- [ ] lint + vet clean

## Notes

Depends on T1's spike result — do not start building the real mechanism before T1 lands.
