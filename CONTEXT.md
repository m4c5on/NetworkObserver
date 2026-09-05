---
status: Living
updated_at: "2026-09-05"
---

# Domain Context — NetworkObserver

## Glossary

- operator — the developer or admin who installs and runs the app on their own Mac to self-diagnose network problems.
- health state — the single overall verdict (good / degraded / unreachable) the app shows in the status bar, derived from combining the gateway probe and the external-host probe. NOT the network interface (Wi-Fi/Ethernet) — the interface is what carries the connection; health state is the result of assessing that connection, not the connection itself.
- probe — one reachability/latency check against one target host (the gateway or the external host), repeated on a fixed interval. NOT health state — a single probe is one data point; health state is the derived verdict built from a batch of probes over time.
