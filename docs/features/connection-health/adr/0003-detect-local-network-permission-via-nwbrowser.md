---
status: Accepted
owner: "ueiktyrj@gmail.com"
reviewers: ["Tech Lead", "Security Lead"]
updated_at: "2026-09-05"
feature_size: "M"
ticket: "connection-health"
---

# 0003 — Detect Local Network permission via an NWBrowser trigger

- **Status:** Accepted
- **Date:** 2026-09-05
- **Deciders:** Architect (this session) + operator/owner

## Context

AC-03/AC-03b require the app to request macOS's "Local Network" permission on first probe and
to show a distinct permission-needed state both before the prompt and after a denial. macOS has
no direct API to query the current grant state — it can only be inferred from the outcome of an
actual local-network action. This decision fixes how the app triggers the OS prompt and infers
denial, and is hard to change later without reworking both `Core/ConnectionProbing` (which must
emit the permission-needed signal) and the Store (which maps it to the AC-03/AC-03b UI state).

## Decision drivers

- AC-03 / AC-03b require a permission-needed state distinguishable from a genuine unreachable
  reading.
- Accuracy NFR (spec §6: ≤1 false state transition per 24h) — conflating "permission denied"
  with "gateway unreachable" would itself be a false/misleading transition.

## Considered options

1. **A short-lived `NWBrowser` on `_bonjour._tcp` (or a locally-scoped browse) at first-probe
   time** — the browse itself is what triggers the OS's Local Network prompt; the browse's
   outcome (finds services / times out with a permission-denied-shaped failure) is read as the
   permission signal.
2. **Attempt the real gateway probe directly and interpret its failure as permission-denied
   when it can't be distinguished from "gateway unreachable"** — no separate trigger mechanism,
   fewer moving parts, but risks conflating two different causes into one state.

## Decision outcome

**Chosen:** Option 1 (NWBrowser trigger). Keeping permission detection as its own step, decoupled
from the real probe, avoids conflating "no permission" with "gateway is down" — a conflation
that would directly cost accuracy (spec §6). This is a documented Apple-community pattern for
triggering the Local Network prompt from apps with no Bonjour feature of their own.

## Consequences

**Positive**
- Permission-needed and gateway-unreachable stay distinguishable states, protecting the
  accuracy NFR.
- The trigger runs once at first probe (and again after a denial-driven Settings visit), not on
  every cycle — negligible overhead.

**Negative**
- Adds a Bonjour-browse code path that exists purely to observe a permission side effect, not
  because the app uses Bonjour for anything else — a small amount of complexity whose only job
  is inferring OS state.

**Neutral**
- **Unverified assumption, flagged in §11:** this ADR assumes (a) a browse triggers the same
  Local Network prompt as a direct unicast connection to the gateway, and (b) its failure mode
  after denial is distinguishable from a timeout. Both need confirming on a real Mac early in
  `implement`; if either is false, the fallback is Option 2 with an explicit accuracy trade-off
  noted in a new risk row.

## Links

- Spec: [[../spec.md]] §6.1, AC-03, AC-03b
- SAD: [[../sad.md]] §4
