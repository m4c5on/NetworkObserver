---
status: Accepted
owner: "ueiktyrj@gmail.com"
reviewers: ["Tech Lead", "Security Lead"]
updated_at: "2026-09-05"
feature_size: "M"
ticket: "connection-health"
---

# 0001 — Ship unsandboxed outside the App Store

- **Status:** Accepted
- **Date:** 2026-09-05
- **Deciders:** Architect (Tech Lead role, this session) + operator/owner

## Context

connection-health's headline feature is automatic root-cause diagnosis: separately probing the
local gateway and a fixed external host to tell an operator whether a connection problem is
local or external. This requires low-level network access (ICMP/raw-socket-style reachability
checks, per §4) that the macOS App Sandbox restricts or forbids outright. `docs/idea-brief.md`
already committed to a non-App-Store distribution for this reason; this ADR records the
decision at the architecture level so later stages (build settings, entitlements, the probing
implementation) don't re-litigate it.

## Decision drivers

- The headline diagnostic capability (spec §1) needs network primitives the App Sandbox
  restricts (raw/ICMP-style sockets to an arbitrary LAN host).
- Spec §3 Non-goals explicitly excludes an in-app update mechanism, which is consistent with —
  and only makes sense under — a non-App-Store distribution.
- Spec §6.1 names non-App-Store distribution as a driver of the mandatory security review.

## Considered options

1. **Ship outside the App Store, unsandboxed, Developer ID signed + notarized** — no App
   Sandbox entitlement restrictions; Gatekeeper is satisfied via notarization instead of App
   Review.
2. **Ship through the App Store under the App Sandbox** — would need to first confirm whether
   the sandbox's `com.apple.security.network.client` entitlement (or any entitlement) permits
   the raw/ICMP-style gateway probe at all; if it doesn't, the headline feature is not
   buildable under this option.

## Decision outcome

**Chosen:** Option 1 (ship outside the App Store, unsandboxed, notarized). The app's entire
value proposition is the local-vs-external diagnosis, which depends on network access the
sandbox may not grant; committing to the unsandboxed path removes that risk entirely rather
than discovering it mid-implementation. This was already the direction set in
`docs/idea-brief.md`; this ADR ratifies it at the architecture level.

## Consequences

**Positive**
- No sandbox entitlement negotiation — the probing code (§4) can use whatever socket APIs the
  chosen protocol strategy needs.
- No App Review cycle blocking releases.

**Negative**
- No App Store discovery/updates — spec §3 already excludes an in-app update checker, so
  operators update manually (a known, accepted limitation, not new debt from this ADR).
- Requires a paid Apple Developer ID + a notarization step in the release process (build/CI
  concern for `tasks`/`implement`).
- First-run Gatekeeper friction is higher than an App Store install if notarization ever lapses
  (e.g., an expired certificate) — operators would see a Gatekeeper block until re-notarized.

**Neutral**
- The placeholder bundle identifier `com.msg.groceriesTracker.*` in `project.pbxproj` must be
  corrected before a real notarized release (tracked as a §11 risk); unrelated to this decision
  but blocking on the same distribution path.

## Links

- Spec: [[../spec.md]] §1, §3, §6.1
- SAD: [[../sad.md]] §4
