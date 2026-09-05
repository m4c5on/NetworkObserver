---
status: Accepted
owner: "ueiktyrj@gmail.com"
reviewers: ["Tech Lead"]
updated_at: "2026-09-05"
feature_size: "M"
ticket: "connection-health"
---

# 0005 — Apply the 3-consecutive-cycle hysteresis to the combined state, in the Reducer

- **Status:** Accepted
- **Date:** 2026-09-05
- **Deciders:** Architect (this session) + operator/owner

## Context

AC-04/AC-04b require the displayed health state to change only after 3 consecutive probe cycles
report the same worse (or better) result, in both directions. The spec's wording ("the health
state moves to a worse level only after 3 consecutive probe cycles report that same worse
result") refers to the singular *health state*, not the raw per-target probe result — but the
rule could still be implemented at either level, and the two produce different behavior: applied
per-target (gateway and external each debounced independently, then combined) vs. applied to the
already-combined per-cycle candidate (per the AC-08 table). This spans `Core/ConnectionProbing`
(source of raw per-cycle results) and the `ConnectionHealthDomain.Reducer` (where the project's
MVI convention requires pure, zero-mock-tested business logic to live).

## Decision drivers

- Spec AC-04/AC-04b wording is stated in terms of the singular health state.
- `.claude/skills/ios-MVI-architecture/SKILL.md` — a pure `Reducer` owns domain logic.
- `.claude/skills/ios-tdd-workflow/SKILL.md` — reducers are unit-tested with zero mocking.
- Accuracy NFR (spec §6: ≤1 false transition/24h) — the hysteresis exists specifically to
  protect this goal, so its exact placement is not a cosmetic detail.

## Considered options

1. **Hysteresis on the AC-08-combined per-cycle candidate, computed in the Reducer** — each
   cycle, Core delivers raw `{gateway, external}` results as one `Intent`; the Reducer first
   derives a candidate overall state via the AC-08 table, keeps a 3-entry window of candidates
   in `State`, and only switches the displayed state once all 3 agree.
2. **Independent per-target hysteresis, then combine** — gateway and external each carry their
   own 3-cycle debounce window before their debounced results are combined via AC-08.

## Decision outcome

**Chosen:** Option 1. It matches the spec's literal wording (hysteresis on "the health state,"
singular), avoids a subtle behavioral trap where two independently-debounced targets could each
individually satisfy their own 3-cycle rule while never producing 3 consecutive *identical
combined* candidates (delaying recovery indefinitely in edge cases), and keeps all of it as one
pure function in the Reducer — directly satisfying the project's zero-mock reducer-testing
convention.

## Consequences

**Positive**
- One state machine, one place to unit-test against AC-04/AC-04b/AC-08 together.
- Matches the spec's literal phrasing, reducing the risk of a reviewer/QA reading AC-04
  differently than the implementation.

**Negative**
- A brief gateway-only blip cannot promote or demote the display on its own until it also shifts
  3 consecutive combined candidates — slightly slower to reflect a gateway-only change than
  Option 2 would be, though this is the intended debounce behavior, not a defect.

**Neutral**
- `State` carries a small fixed-size (3-entry) history buffer of combined candidates instead of
  two separate 3-entry buffers — marginally simpler memory shape, immaterial to the ≤50MB NFR.

## Links

- Spec: [[../spec.md]] AC-04, AC-04b, AC-08
- SAD: [[../sad.md]] §4, §5
