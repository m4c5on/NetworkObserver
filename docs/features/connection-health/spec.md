---
status: Draft
owner: "ueiktyrj@gmail.com"
reviewers: ["Tech Lead", "Security Lead"]
updated_at: "2026-09-05"
feature_size: "M"
---

# Spec — connection-health

> **Glossary:** [CONTEXT](../../../CONTEXT.md)
> **Reference module / docs / channels used:** None — only the interview + `docs/idea-brief.md` + CONTEXT.md.

## 1. Context

Operators (developers and admins who diagnose network problems on their own Mac) currently
have no quick, glanceable way to tell whether a connection problem is local (their own Wi-Fi
or router) or external (the internet or their ISP). Today that requires manually opening a
system monitor or running commands in a terminal — and even then, a single "connection is
bad" reading doesn't say where the fault is.

There is no specific incident or deadline behind this — the gap surfaced while comparing
against existing macOS menu-bar network tools (bandwidth/traffic monitors), which leave "is
it my network or the internet" unanswered at a glance.

The committed approach: a minimal macOS menu-bar app, distributed outside the App Store,
whose headline feature is automatic root-cause diagnosis — comparing latency to the local
gateway against latency to a fixed external host so it can tell the operator whether a
problem is local or external, not just that something is slow.

This spec is sourced from `docs/idea-brief.md` (interview, medium depth) and this run's own
easy-depth deep-dive; assumptions this run made instead of asking are recorded inline in §8
and were batch-approved by the owner (see conversation).

## 2. Goals

- Operators can tell, from the status bar alone, whether an active connection problem is
  local or external — without opening any other tool.
- The app earns operator trust by keeping false alarms rare enough that a degraded or
  unreachable reading is always worth investigating.
- The app runs continuously with negligible resource overhead, so operators leave it running
  at all times rather than opening it only when something feels wrong.

## 3. Non-goals

- Per-app traffic/bandwidth breakdown — not the chosen metric (connection quality, not
  speed); already covered by existing menu-bar monitors.
- Packet capture / deep traffic inspection — a different access level and complexity than a
  lightweight status indicator.
- Historical graphs/trends over days or weeks — v1 shows current state only.
- Push notifications or external alerting (chat/email) — v1 is a local visual indicator only.
- Distinguishing "the external host itself is blocked" from "the internet is fully down" —
  both look identical in v1 (see §8); disambiguating would need multiple external targets,
  deferred past v1.

## 4. User stories

### US-01: Glance at connection health

**As an** operator
**I want** to see a color-coded health indicator in the status bar
**So that** I can tell at a glance whether my connection is fine without opening any other
tool

### US-02: Diagnose local vs external

**As an** operator
**I want** to click the indicator and see the gateway and external-host results separately
**So that** I know whether a problem is in my local network or upstream/the internet

### US-03: Configure probe interval

**As an** operator
**I want** to adjust how often the app probes
**So that** I can balance faster problem detection against network/battery overhead

### US-04: Grant network permission

**As an** operator
**I want** to be clearly told when the app needs local network permission to probe
**So that** I understand why it isn't working if I deny that permission

### US-05: Recognize severity levels

**As an** operator
**I want** the indicator to distinguish "everything's fine" from "degraded" from "fully
unreachable"
**So that** I can judge how urgent the problem is

### US-06: Trust degraded readings

**As an** operator
**I want** the health state to change only after a consistent pattern of probe results, not a
single blip
**So that** I don't get alarmed by false positives

## 5. Acceptance criteria

### AC-01 (US-01) — happy path

**Given** the operator's Mac has good gateway and external-host latency
**When** the app completes a probe cycle
**Then** the status bar shows the good-health color and nothing else

### AC-02 (US-02) — cross-context

**Given** the local gateway probe is succeeding but the external-host probe is failing
**When** the operator clicks the indicator
**Then** the system shows that the local network is fine and the problem is external, rather
than a single ambiguous "bad connection" reading

### AC-03 (US-04) — authorization

**Given** the operator has not granted the app local network permission
**When** the app attempts to run its first probe cycle
**Then** the system shows a permission-needed state and explains that probing requires the
operator to grant local network access, instead of silently showing an incorrect health state

### AC-04 (US-06) — domain invariant

**Given** a single probe to the external host fails while recent prior probes succeeded
**When** the app evaluates the health state
**Then** the system keeps the health state at its current level rather than jumping straight
to unreachable, honoring the rule that health state changes only after a consistent pattern of
probe results

### AC-05 (US-03) — error

**Given** the operator is setting the probe interval
**When** the operator enters a value below the minimum allowed interval
**Then** the system rejects the value, tells the operator the minimum allowed interval, and
keeps the previous valid interval in effect

### AC-06 (US-05) — happy path

**Given** the gateway probe succeeds but takes noticeably longer than normal while the
external probe still succeeds
**When** the app evaluates the health state
**Then** the system shows the degraded-health color, visibly distinct from both the
good-health and unreachable-health colors

## 6. Non-functional requirements

| Aspect | Target | Measurement |
|---|---|---|
| Status update latency (probe completion → status bar reflects it) | ≤ 250 ms | local instrumentation during development |
| Idle resource overhead (CPU) | ≤ 1% average | Activity Monitor sample, 1-hour idle soak test |
| Idle resource overhead (memory) | ≤ 50 MB resident | Activity Monitor sample, 1-hour idle soak test |
| Availability (crash-free sessions) | ≥ 99% | soak-test log over a 7-day continuous run |
| Accuracy (false-positive rate) | ≤ 1 false degraded/unreachable reading per 24h | soak-test log compared against known-good network state |

## 6.1 Security / privacy

- **Data classification:** Internal — network health readings describe the operator's own
  local environment; nothing shared or regulated.
- **Personal data touched:** None — no accounts, no data leaves the device (batch-approved
  assumption).
- **AuthZ/AuthN impact:** Single-operator local app with no roles. The only permission
  boundary is the OS-level local network access grant needed to send probes; the app must
  request it explicitly and handle denial (AC-03) rather than probing silently.
- **Abuse cases:**
  - Excessive probe frequency used to flood the local network: the enforced minimum probe
    interval (AC-05) blocks intervals below the safe floor.
  - A process other than the app's own settings UI changing the probe interval: only the
    operator, through the app's own settings, can change it (the probed hosts themselves are
    fixed, not user-editable, in v1).
  - A spoofed local gateway response producing a false "good" reading: accepted risk for v1 —
    standard reachability checks are not cryptographically authenticated; documented, not
    mitigated.
- **Security review:** Required — new OS-level network-permission boundary (AC-03) and
  non-App-Store distribution (committed in §1 / `docs/idea-brief.md`).

## 7. Metrics / KPIs

- **Adoption** — baseline: 0 installs, target: ≥100 installs within 60 days of v1 release.
- **Diagnostic value** — baseline: 0 (no current tool answers "local or external" at a
  glance), target: ≥80% of surveyed operators report they no longer open Terminal/Activity
  Monitor for this specific question, within 30 days of release.
- **Trust / false-positive rate** — baseline: TBD (no probing logic exists yet), target: ≤1
  false degraded/unreachable reading per 24h of continuous operation, verified in the first
  internal beta soak test.
- **Resource-overhead complaints** — baseline: 0, target: 0 user-reported battery/CPU
  complaints in the first 30 days post-release.

## 8. Open questions

- [ ] Should v1 add a second external host as a fallback, to distinguish "that one host is
  blocked" from "the internet is down"? Default now: accept the false positive, single fixed
  external host (see §3 Non-goals). — owner: design, due: before `sdd:design`
- [ ] What is the default probe interval and its enforced minimum floor (AC-05)? Default now:
  5s default / 1s minimum (batch-approved assumption). — owner: design, due: before
  `sdd:design`
- [ ] Exact minimum supported macOS version(s)? Default now: current and previous major
  release (batch-approved assumption). — owner: design, due: before `sdd:design`
- [ ] Does the status-bar color indicator need a colorblind-safe fallback beyond the palette
  itself (e.g. shape/icon variation)? Default now: colorblind-safe palette only, no additional
  shape/icon indicator (batch-approved assumption). — owner: design, due: before `sdd:design`
