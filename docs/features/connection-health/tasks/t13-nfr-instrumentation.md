---
id: T13
title: "NFR instrumentation: status-update latency + soak-test logging"
layer: "tests"
deps: ["T10"]
acs: []
files_hint: ["NetworkObservationTests/ConnectionHealth/", "Core/ConnectionProbing/"]
owner: "iOS/macOS Engineer"
estimate: "S"
status: "todo"
---

# T13 — NFR instrumentation: status-update latency + soak-test logging

## Why

Derives from [spec §6 QG-1/QG-3/QG-4/QG-5](../spec.md) and [sad §8](../sad.md): all NFR
verification is local-only (no telemetry leaves the device) — `os_log` is the crosscutting
observability convention this feature establishes.

## What

Add an `os_log` (subsystem/category, per sad §8) instrumentation point that logs a timestamp at
probe-cycle completion and again when the Store publishes the resulting `State`, so soak testing
can derive QG-3's ≤250ms status-update latency; log every confirmed health-state transition (not
every probe cycle) so soak-test logs can derive QG-1's false-positive rate and QG-4's detection
latency.

## Definition of Done

- [ ] A test confirms exactly one log line is emitted per probe cycle for the latency
      measurement
- [ ] A test confirms a log line is emitted only on a confirmed state transition, not on every
      candidate
- [ ] lint + vet clean

## Notes

This is local-instrumentation only, per spec §6.1 (no data leaves the device) — not a
crash-reporting or telemetry service.
