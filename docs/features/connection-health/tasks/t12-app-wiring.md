---
id: T12
title: "Wire MenuBarExtra scene + Store DI at app entry"
layer: "wiring"
deps: ["T11"]
acs: []
files_hint: ["App/NetworkObservationApp.swift"]
owner: "iOS/macOS Engineer"
estimate: "S"
status: "todo"
---

# T12 — Wire MenuBarExtra scene + Store DI at app entry

## Why

Derives from [sad §5](../sad.md): `NetworkObservationApp.swift` is the composition root — it
constructs the real probe/settings services and injects them into `ConnectionHealthStore.init`,
then hosts `ConnectionHealthView` in a `MenuBarExtra` scene.

## What

In `App/NetworkObservationApp.swift`, construct `GatewayProbe`, `ExternalHostProbe`,
`LocalNetworkPermission`, `NetworkInterfaceMonitor` and `ConnectionHealthSettings`, inject them
into a `ConnectionHealthStore`, and host `ConnectionHealthView` inside a `MenuBarExtra` scene.

## Definition of Done

- [ ] The app builds via `xcodebuild build` (per `architecture-map.md` build_cmd)
- [ ] A manual smoke run confirms the status-bar icon appears and the app doesn't crash on launch
- [ ] lint + vet clean

## Notes

Composition-root only — no new logic. The pre-existing Xcode-template leftovers
(`ContentView.swift`, `Item.swift`) and the placeholder bundle identifier are out of this task's
scope (sad §11 risks, owned by `scaffold`/release prep respectively).
