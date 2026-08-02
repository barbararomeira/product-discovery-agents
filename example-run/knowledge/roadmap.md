Refreshed: 2026-08-02

# Northwind Robotics — product & roadmap (example)

**This is your roadmap, in the form the agents read.** It is what lets them tell a genuinely new
request from something you shipped last quarter, and it is why a briefing can say *"this validates
Real-time alerts, committed Q2"* instead of just *"customer wants alerts"*.

Keep it short — four headings, one line per item. Rewrite it whenever the roadmap moves; the agents
re-read it on a schedule (`product_knowledge.refresh_days`). If your roadmap already lives in a wiki
page, a sheet or a doc, point `product_knowledge.remote` at it instead and this file becomes a cache.

## Shipped today
- **Line dashboard** — throughput, cycle time and downtime per line, refreshed hourly.
- **Downtime log** — operators tag a stop with a reason code from a fixed list.
- **Weekly PDF report** — emailed Monday, one page per line.
- **User management** — roles: viewer, supervisor, admin.
- **CSV export** — any dashboard view, manual download.

## Committed (with dates)
- **Real-time alerts (Q2)** — push a message when a line drifts from its target for more than 10 minutes.
- **Shift comparison view (Q2)** — compare the same line across shifts and crews.
- **Single sign-on / SAML (Q3)** — enterprise identity providers.
- **Mobile layout (Q3)** — the dashboard on a phone, read-only.

## In discovery (not committed, no dates)
- **Root-cause suggestions** — cluster recurring stops and propose likely causes.
- **Maintenance-system integration** — read work orders so downtime can be attributed to planned maintenance.
- **Multi-site rollup** — one view across plants for regional managers.

## Explicitly deferred (the parking lot)
- **Public API** — asked for repeatedly; parked until at least three customers commit to building against it.
- **On-premise deployment** — cloud only for now.
- **Custom report builder** — the weekly PDF covers most of the need.
