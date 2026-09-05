---
status: Draft
owner: "ueiktyrj@gmail.com"
reviewers: ["Tech Lead", "Security Lead"]
updated_at: "2026-09-05"
feature_size: "M"
target_surfaces: []
---

# Software Architecture Document — connection-health

## 1. Introduction and goals

**Intent.** connection-health gives operators (the developer/admin who installs and runs the
app on their own Mac to self-diagnose network problems — CONTEXT glossary) a glanceable,
color-coded menu-bar health indicator that distinguishes a local (gateway) problem from an
external (internet) problem, so they no longer need to open Activity Monitor or a terminal to
answer "is it my network or the internet." The indicator must be trustworthy enough (rare
false alarms) that operators leave it running continuously, and light enough that doing so
costs them nothing noticeable.

**Top-3 quality goals (1-liners; full scenarios in §10):**

1. **Accuracy** — false alarms are rare enough to trust a degraded/unreachable reading (spec
   §6: ≤ 1 false state transition into degraded/unreachable per 24h). This is the headline
   trust goal (spec §2).
2. **Resource efficiency** — negligible idle overhead so operators leave the app running at
   all times (spec §6: ≤ 1% CPU, ≤ 50 MB resident at the default probe interval).
3. **Responsiveness** — the status bar reflects reality fast enough to be useful mid-incident
   (spec §6: ≤ 250 ms status update latency; ≤ 3 probe intervals / ≤ 15 s detection latency).

**Stakeholders.**

| Role | Interest | Sign-off owner? |
|---|---|---|
| Operator (CONTEXT glossary) | Sole end user — reads the indicator daily to self-diagnose network problems | No |
| Tech Lead | SAD approval | Yes |
| Security Lead | Reviews the Local Network permission boundary and non-App-Store distribution posture (spec §6.1) | Yes |

<!-- Decision overrides (¶4) — populated by the critic resolution loop, empty otherwise. -->

## 2. Constraints

**Technical.**
- Swift 5 (`NetworkObservation.xcodeproj/project.pbxproj`: `SWIFT_VERSION = 5.0`)
- SwiftUI (`MenuBarExtra` scene) for the UI; Foundation + Network framework for the probes
- No datastore — settings only, persisted via `UserDefaults` (`@AppStorage`)
- Architecture convention: MVI (Model → View → Intent) per `.claude/skills/ios-MVI-architecture/SKILL.md` — mandatory for every feature screen, including this one
- Minimum supported macOS: current major release and the previous one (batch-approved assumption, spec §8) — no older API surface is targeted

**Organisational.**
- No fixed deadline or PR-count budget stated in the spec; sized M (1–2 sprints) per `.size`
- Single-developer/indie project (no team-composition constraint beyond the Architect/Tech Lead role)

**Conventions.**
- `.claude/skills/ios-MVI-architecture/SKILL.md` — Store/Reducer/View contract, dependency injection into `Store.init`, `Intent._loadingFailed(Error)` error surfacing
- `.claude/skills/ios-tdd-workflow/SKILL.md` — reducers/use-cases unit-tested with zero mocking
- No ID strategy — v1 has no persisted entities with IDs

**Regulatory / external.**
- No data leaves the device (spec §6.1) — no compliance regime applies
- Non-App-Store distribution is a fixed constraint carried from `docs/idea-brief.md` (unsandboxed, notarized) — see §4 for the confirming decision and its ADR


