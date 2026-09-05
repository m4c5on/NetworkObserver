---
status: Accepted
owner: "ueiktyrj@gmail.com"
reviewers: ["Tech Lead", "Security Lead"]
updated_at: "2026-09-05"
feature_size: "M"
ticket: "connection-health"
---

# 0004 — ICMP for the gateway probe, TCP/TLS handshake for the external probe

- **Status:** Accepted
- **Date:** 2026-09-05
- **Deciders:** Architect (this session) + operator/owner

## Context

Spec §6.1 fixes the external-host probe as TCP/HTTPS-based, explicitly excluding ICMP (corporate
and captive-portal networks commonly block it, which would read as a false "unreachable"). It
does not exclude ICMP for the gateway probe, since the local gateway is on the operator's own
LAN, not behind a third party's firewall. This decision fixes the concrete mechanism for each
probe — a single choice, since both feed the same AC-08 combination table and both must produce
a latency number under the ≤250ms status-update NFR.

## Decision drivers

- Spec §6.1: external probe must be TCP/HTTPS-based, never ICMP.
- ADR-0001 (unsandboxed distribution) — removes the App Sandbox restriction that would have
  blocked raw/ICMP-style sockets.
- Status-update latency NFR (spec §6: ≤250ms) — both probes must resolve quickly.

## Considered options

1. **ICMP echo (unprivileged "ping socket", `SOCK_DGRAM`/`IPPROTO_ICMP`) for the gateway; a raw
   TCP+TLS handshake to a fixed IP:port (no HTTP request) for the external host** — each probe
   uses the most direct signal available for its target's environment.
2. **TCP-connect for both targets** (a fixed port on the gateway, e.g. 80/443, plus the same
   TLS handshake for the external host) — one uniform mechanism, no ICMP anywhere.

## Decision outcome

**Chosen:** Option 1. ICMP is the correct tool for a LAN reachability/latency check — it's what
gateway "ping" fundamentally means, and no corporate/captive-portal blocking concern applies on
the operator's own subnet. The external host keeps the TCP/TLS handshake spec §6.1 already
requires, without an HTTP request layered on top (avoiding a dependency on the target's HTTP
response body or DNS resolution — the external target is a fixed IP:port).

## Consequences

**Positive**
- Each target gets the most reliable and lowest-overhead signal for its context.
- The external probe's TLS-handshake-only design has no DNS dependency and no reliance on a
  specific HTTP response, so a router/CDN change on the target's HTTP layer can't break it.

**Negative**
- Two different code paths to implement and test (an ICMP ping-socket path and a TLS-handshake
  path) instead of one uniform TCP-connect path.

**Neutral**
- **Unverified assumption, flagged in §11:** unprivileged ICMP `SOCK_DGRAM` sockets on macOS,
  unsandboxed, without elevated privileges — documented in community/Apple-sample-code
  discussions (e.g. the `SimplePing` pattern) but not confirmed empirically in this session.
  Needs a short spike at the start of `implement`; the documented fallback is Option 2's
  TCP-connect-to-gateway approach if it doesn't hold, accepting the "some routers don't listen
  on any fixed port" risk noted alongside it.

## Links

- Spec: [[../spec.md]] §6.1, AC-02, AC-08
- SAD: [[../sad.md]] §4, §3
