Refreshed: 2026-08-02

# Northwind Robotics — product knowledge (example)

This is the file the agents read to tell "new request" from "we shipped that last quarter".
Keep it short. Four headings, a line each. Rewrite it whenever the roadmap moves.

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
