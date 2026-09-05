---
status: Draft
owner: "ueiktyrj@gmail.com"
updated_at: "2026-09-05"
depth: "medium"
---

# Idea brief — connection-health

## 1. Raw idea

network-observation for mac os in status bar

## 2. Problem

Developers and admins currently have no quick, glanceable way to tell whether a network
problem is local (their own Wi-Fi/router) or external (the internet/ISP) — today that
requires manually opening a system monitor or running ping/lookup commands in a
terminal, and even then a single number for "the connection" doesn't say where the
fault is.

## 3. Users

Developers and admins who personally diagnose network problems on their own Mac — a
technical audience, not general consumers.

## 4. Why now

No specific incident or deadline triggered this — it surfaced as a gap while comparing
against existing menu-bar network tools, which focus on bandwidth/traffic and leave
"is it my network or the internet" unanswered at a glance.

## 5. Out of scope

- Per-app traffic breakdown / bandwidth statistics — not the chosen metric (connection
  quality, not speed), and already covered by existing menu-bar monitors.
- Packet capture / deep traffic inspection — different access level and complexity than
  a lightweight status indicator.
- Historical graphs/trends over days or weeks — v1 shows current state only.
- Push notifications or external alerting (chat/email) — v1 is a local visual indicator
  only.
- App Store distribution — the diagnostic probes need permissions the sandbox
  restricts, so v1 ships outside the App Store.

## 6. Risks

- Weakest spot: if the local-vs-external diagnosis isn't the obvious headline feature
  in the UI, the product reads as "just another network monitor" next to established
  menu-bar tools — assumes users notice the two-point comparison; false if it's buried
  behind a click and looks like a generic status dot.
- Assumes network probes are representative of real connection health; false if a
  single noisy probe flips the indicator to a bad state and erodes trust exactly when
  the user needs to rely on it.
- Assumes users will accept installing outside the App Store; false if the lack of App
  Store discovery/trust suppresses adoption.
- Assumes users will tune the probe interval/targets themselves; false if the defaults
  are wrong for a given network and nobody opens settings to fix it.

## 7. Recommendation

Build a minimal macOS menu-bar app, distributed outside the App Store, whose single
headline feature is automatic root-cause diagnosis: it compares latency to the local
gateway against latency to a fixed external host so it can tell the user whether a
problem is "your network" or "the internet" — not just that something is slow. The
status bar itself shows only a color-coded health indicator; clicking reveals the
gateway-vs-external breakdown and the user-configurable probe interval. Bandwidth
stats, packet capture, history, and alerting all stay out of v1 so the product doesn't
blur into a clone of existing traffic monitors.

## 8. Open questions

- No internet at all vs. slow internet — same degraded state or a distinct one? (owner:
  product, before design)
- Is a single fixed external host enough for day one, or does it need a fallback if
  that host itself becomes unreachable/blocked? (owner: design)
- Does the color-only indicator need a colorblind-safe fallback (shape/icon variation)?
  (owner: design)
