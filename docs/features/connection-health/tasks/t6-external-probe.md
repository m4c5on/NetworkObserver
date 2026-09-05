---
id: T6
title: "ExternalHostProbe: TCP/TLS handshake to 1.1.1.1:443"
layer: "infra"
deps: ["T3"]
acs: ["AC-02", "AC-08"]
files_hint: ["Core/ConnectionProbing/ExternalHostProbe.swift"]
owner: "iOS/macOS Engineer"
estimate: "S"
status: "todo"
---

# T6 — ExternalHostProbe: TCP/TLS handshake to 1.1.1.1:443

## Why

Derives from [spec §6.1](../spec.md) (TCP/HTTPS-based, never ICMP), [ADR-0004](../adr/0004-icmp-gateway-tls-handshake-external-probes.md)
and the §4 config decision fixing `1.1.1.1:443` as the target.

## What

In `Core/ConnectionProbing/ExternalHostProbe.swift`, implement a bare TCP+TLS handshake (no HTTP
request) to the fixed IP `1.1.1.1:443`, returning reachability + latency (or a timeout). No DNS
resolution and no dependency on an HTTP response body.

## Definition of Done

- [ ] Unit/integration tests confirm a successful handshake returns a latency value
- [ ] Unit/integration tests confirm a timeout/failure is reported distinctly
- [ ] A test or code-review check confirms no ICMP socket is used anywhere in this file
- [ ] lint + vet clean

## Notes

No dependency on T1/T2 — this probe's mechanism (TCP/TLS) was never in question.
