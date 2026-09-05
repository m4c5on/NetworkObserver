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

- Operators can tell the connection's overall health at a glance from the status bar; a
  single click on the app's own indicator (not any other tool) reveals whether an active
  problem is local or external.
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
- Correct behavior while an active VPN is connected, or while multiple network interfaces
  are active at once (e.g. Wi-Fi + Ethernet) — v1 evaluates only the OS's default-route
  gateway; accuracy under VPN or multi-homed setups is not guaranteed.
- An automatic update-checking mechanism for the out-of-App-Store distribution — v1 ships
  with no in-app update check; operators update manually.

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
than a single ambiguous "bad connection" reading, and the status bar shows the
unreachable-health color (per the AC-08 result mapping, since the external probe is the one
that determines overall severity)

### AC-03 (US-04) — authorization, not yet requested

**Given** the operator has not yet been asked to grant the app local network permission
**When** the app attempts to run its first probe cycle
**Then** the system requests local network permission from the operator and shows a
permission-needed state (the unreachable-health color, with menu text explaining that
permission is required) instead of silently showing an incorrect health state

### AC-03b (US-04) — authorization, denied

**Given** the operator has denied the app local network permission
**When** the app attempts to run a probe cycle
**Then** the system shows the permission-needed state and explains that the operator must
grant local network access in System Settings, since the OS will not show the permission
prompt again after a denial

### AC-04 (US-06) — domain invariant

**Given** a single probe to the external host fails while the health state is currently good
**When** the app evaluates the health state
**Then** the system keeps the health state at good rather than jumping straight to a worse
level; the health state moves to a worse level only after 3 consecutive probe cycles report
that same worse result

### AC-04b (US-06) — domain invariant, recovery

**Given** the health state is currently degraded or unreachable and a single probe now
succeeds
**When** the app evaluates the health state
**Then** the system keeps the health state at its current (worse) level rather than jumping
straight to good; the health state recovers to a better level only after 3 consecutive probe
cycles report that better result (the same 3-consecutive-probe rule as AC-04, applied
symmetrically in both directions)

### AC-05 (US-03) — error

**Given** the operator is setting the probe interval
**When** the operator enters a value below the minimum allowed interval
**Then** the system rejects the value, tells the operator the minimum allowed interval, and
keeps the previous valid interval in effect; there is no enforced maximum interval in v1, only
the enforced minimum

### AC-06 (US-05) — happy path

**Given** the gateway probe succeeds but its latency exceeds a fixed threshold (the exact
value is set at `design`, see §8) while the external probe still succeeds
**When** the app evaluates the health state
**Then** the system shows the degraded-health color, visibly distinct from both the
good-health and unreachable-health colors

### AC-07 (US-01) — edge case

**Given** the operator's Mac has no active network interface (Wi-Fi off, no cable connected)
**When** the app attempts a probe cycle
**Then** the status bar shows a distinct "no network" state, visibly different from the
unreachable-health color, so the operator understands the cause is the absence of a network
connection rather than a network fault

### AC-08 (US-02) — domain invariant

**Given** the gateway probe and the external-host probe each independently report one of
{ok, slow, failing}
**When** the app evaluates the health state
**Then** the system derives the overall health state from the external-host probe result as
the primary signal — external ok (with gateway ok or slow) → good or degraded per AC-06;
external slow → degraded regardless of the gateway result; external failing → unreachable
regardless of the gateway result — while the gateway result is shown on click (AC-02) to
explain whether the cause is local or external, per the following mapping:

| Gateway ＼ External | ok | slow | failing |
|---|---|---|---|
| ok | good | degraded | unreachable |
| slow | degraded | degraded | unreachable |
| failing | unreachable | unreachable | unreachable |

## 6. Non-functional requirements

| Aspect | Target | Measurement |
|---|---|---|
| Status update latency (probe completion → status bar reflects it) | ≤ 250 ms | local instrumentation during development |
| Detection latency (real outage onset → status bar reflects the worse state) | ≤ 3 probe intervals (≤ 15s at the default 5s interval) | derived from the AC-04 3-consecutive-probe rule; verified in soak testing |
| Idle resource overhead (CPU), at the default probe interval | ≤ 1% average | Activity Monitor sample, 1-hour idle soak test at the default interval; probing pauses during system sleep (standard macOS suspend/resume) |
| Idle resource overhead (memory), at the default probe interval | ≤ 50 MB resident | Activity Monitor sample, 1-hour idle soak test at the default interval |
| Availability (crash-free sessions) | ≥ 99% | soak-test log over a 7-day continuous run |
| Accuracy (false-positive rate) | ≤ 1 false state transition into degraded/unreachable per 24h | soak-test log compared against known-good network state; counted per false transition, not per probe cycle |

## 6.1 Security / privacy

- **Data classification:** Internal — network health readings describe the operator's own
  local environment; nothing shared or regulated.
- **Personal data touched:** None — no accounts, no data leaves the device (batch-approved
  assumption).
- **AuthZ/AuthN impact:** Single-operator local app with no roles. The only permission
  boundary is the OS-level local network access grant needed to send probes; the app must
  request it explicitly and handle denial (AC-03b) rather than probing silently.
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
- **Probe protocol:** The external-host probe uses a TCP/HTTPS-based reachability check, not
  ICMP — ICMP is commonly blocked by corporate and captive-portal networks, which would
  otherwise read as a false "unreachable" (the exact host is a separate open question, §8).

## 7. Metrics / KPIs

- **Adoption** — baseline: 0 installs, target: ≥100 installs within 60 days of v1 release;
  measured externally (download-page analytics), not via in-app telemetry (per §6.1, no data
  leaves the device).
- **Diagnostic value** — baseline: 0 (no current tool answers "local or external" at a
  glance), target: ≥80% of surveyed operators report they no longer open Terminal/Activity
  Monitor for this specific question, within 30 days of release.
- **Trust / false-positive rate** — baseline: TBD (no probing logic exists yet), target: ≤1
  false state transition into degraded/unreachable per 24h of continuous operation (same
  counting unit as §6 Accuracy), verified in the first internal beta soak test.
- **Resource-overhead complaints** — baseline: 0, target: 0 user-reported battery/CPU
  complaints in the first 30 days post-release; measured via user reports/surveys, not via
  in-app telemetry (per §6.1, no data leaves the device).

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
- [ ] Exact gateway-latency threshold (in ms) that triggers the degraded state (AC-06)?
  Default now: fixed absolute threshold (not an adaptive per-network baseline, per `clarify`
  resolution); the number itself is set at `design`. — owner: design, due: before `sdd:design`
