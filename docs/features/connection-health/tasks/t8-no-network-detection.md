---
id: T8
title: "Detect no active network interface"
layer: "infra"
deps: ["T3"]
acs: ["AC-07"]
files_hint: ["Core/ConnectionProbing/NetworkInterfaceMonitor.swift"]
owner: "iOS/macOS Engineer"
estimate: "S"
status: "todo"
---

# T8 — Detect no active network interface

## Why

Derives from [spec AC-07](../spec.md) and [sad §6 Flow 5](../sad.md): the "no network" state
must be kept distinct from a probe timeout/failure, so a "cable unplugged" reading is never shown
as a network fault.

## What

In `Core/ConnectionProbing/NetworkInterfaceMonitor.swift`, implement a check for an active
network interface (Wi-Fi or Ethernet) before a probe cycle runs, emitting a distinct
no-active-interface signal when none is found.

## Definition of Done

- [ ] Unit tests confirm the signal fires when no interface is active
- [ ] Unit tests confirm the signal is distinguishable from a probe timeout
- [ ] lint + vet clean

## Notes

No dependency on T1/T2 — this is a separate OS-level check, not a probe result.
