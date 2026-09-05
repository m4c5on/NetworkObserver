---
status: Accepted
owner: "Architect"
reviewers: []
updated_at: "2026-09-05"
feature_size: "N/A — foundational (repo-level)"
ticket: "N/A"
---

# 0001 — Build the menu-bar app in Swift + SwiftUI using MenuBarExtra

- **Status:** Accepted
- **Date:** 2026-09-05
- **Deciders:** Architect + Maksym (survey greenfield session)

## Context

`docs/idea-brief.md` calls for a lightweight macOS menu-bar app, distributed outside the App Store,
whose headline feature is comparing gateway-vs-external latency to diagnose network problems. The
repo currently contains only Xcode's default SwiftUI+SwiftData document-app template — no real
architecture has been chosen yet. This decision fixes the stack before any feature code is written.

## Decision drivers

- Target platform is macOS only, status-bar-resident, no cross-platform requirement (idea-brief §3
  scopes to "developers and admins ... on their own Mac").
- Outside App Store distribution is already decided (idea-brief §5/§7), removing any pressure toward
  UIKit-for-App-Store-compatibility concerns.
- Minimize new dependencies — a single developer maintaining an indie diagnostic tool.

## Considered options

1. **SwiftUI `MenuBarExtra`** — native SwiftUI API (macOS 13+) for a status-bar scene, declarative UI
   for the popover/breakdown view.
2. **AppKit `NSStatusItem` + manually managed `NSPopover`** — the older, more manual approach; more
   control over status-bar icon behavior, more boilerplate.
3. **Non-Swift stack (e.g. Electron menu-bar wrapper)** — cross-platform tooling, heavier runtime,
   no macOS-native feel.

## Decision outcome

**Chosen:** Option 1, SwiftUI `MenuBarExtra`. The project already targets a high macOS deployment
version (`MACOSX_DEPLOYMENT_TARGET = 26.5`), so `MenuBarExtra`'s macOS 13+ requirement is not a
constraint, and it gives a declarative, low-boilerplate status-bar UI that fits a single-feature v1.
AppKit is available as an escape hatch later if `MenuBarExtra` proves too limiting for icon/animation
needs, but nothing in the idea brief demands it now.

## Consequences

**Positive**
- Least code for a status-bar icon + popover, matching v1's minimal scope.
- Stays in SwiftUI throughout — no UIKit/AppKit bridging code needed for the UI layer.

**Negative**
- Less fine-grained control over the status-bar icon than raw `NSStatusItem` (e.g. custom animations
  may need workarounds).

**Neutral**
- Dropping to AppKit for the status item specifically remains possible later without restructuring
  the rest of the app.

## Links

- Idea brief: [[../idea-brief.md]]
- Architecture map: [[../architecture-map.md]]
- Related ADR: [[0002-mvi-architecture-style]]
