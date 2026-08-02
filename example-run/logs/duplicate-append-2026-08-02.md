# Duplicate append — 2026-08-02

Two daily runs wrote to `signal-matrix.xlsx` at the same time. Each appended a full,
independently-worded set of the same 19 signals from the same five calls, and each then removed
the other's block — which briefly emptied the sheet. The matrix was restored to a single canonical
set of 19 rows. The other run then terminated with a connection error at 19:46 (`logs/failures.log`),
so this run is the surviving one.

The kept rows use the other run's wording, because the existing `needs-review.md` describes them.
This file preserves the wording that was **not** kept, so nothing is lost. Where the two versions
scored a signal differently, the difference is listed in `needs-review.md` item 5.

| Signal | Type | Audience | Roadmap status | Customers | Mentions | Priority |
|---|---|---|---|---|---|---|
| Line status on a phone for supervisors who have no desk | Roadmap validation | Prospect, Customer | On roadmap — committed (Mobile layout, Q3) | Vertex Motors: 2, Acme Foods: 2 | 2 | 8 |
| Tell me which stop keeps coming back | Roadmap validation | Prospect, Customer | On roadmap — discovery (Root-cause suggestions) | Acme Foods: 2, Vertex Motors: 1 | 2 | 6 |
| Let customers edit the downtime reason list | Enhancement — Gap | Prospect, Customer | Not planned | Acme Foods: 2 | 2 | 4 |
| One view across all plants | Roadmap validation | Prospect, Customer | On roadmap — discovery (Multi-site rollup) | Acme Foods: 1 | 2 | 2 |
| Tell me during the shift, not after it | Roadmap validation | Prospect | On roadmap — committed (Real-time alerts, Q2) | Acme Foods: 2 | 1 | 2 |
| Alerts delivered into the chat tool people use on shift | New feature | Customer | Unclear — needs Alex Kim | Lumen Devices: 2 | 1 | 2 |
| Sign in through the company identity provider | Roadmap validation | Prospect | On roadmap — committed (Single sign-on / SAML, Q3) | Vertex Motors: 2 | 1 | 2 |
| Show workers exactly what is stored about them | New feature | Implementation | Not planned | Halden Pumps: 2 | 1 | 2 |
| Create and remove users in bulk | Enhancement — Gap | Implementation | Unclear — needs Alex Kim | Halden Pumps: 2 | 1 | 2 |
| Pull the raw numbers into the customer's own warehouse | New feature | Prospect | Deferred (Public API — parked until three customers commit) | Vertex Motors: 2 | 1 | 2 |
| Separate planned maintenance from unplanned downtime | Enhancement — Gap | Customer | On roadmap — discovery (Maintenance-system integration) | Lumen Devices: 2 | 1 | 2 |
| Compare the same line across shifts and crews | Roadmap validation | Customer | On roadmap — committed (Shift comparison view, Q2) | Lumen Devices: 2 | 1 | 2 |
| Flag numbers that look wrong | New feature | Customer | Not planned | Acme Foods: 2 | 1 | 2 |
| Counter double-reports output after a line restart | Bug | Customer | Shipped (defect — reported fixed on the call) | Acme Foods: 2 | 1 | 2 |
| Read planned stops from the maintenance system | Roadmap validation | Customer | On roadmap — discovery (Maintenance-system integration) | Lumen Devices: 1 | 1 | 1 |
| Comparison against the same day last week lands well | Enhancement — Amplify | Prospect | Shipped (Line dashboard) | Vertex Motors: 1 | 1 | 1 |
| Choose when the recurring report is generated | Enhancement — Gap | Implementation | Not planned | Halden Pumps: 1 | 1 | 1 |
| Report type too small at the size it is actually printed | Enhancement — Gap | Customer | Not planned | Lumen Devices: 1 | 1 | 1 |
| Line filter resets when the date range changes | Bug | Implementation | Shipped (defect) | Halden Pumps: 1 | 1 | 1 |

Rows preserved: 19

Full pain-point text, quotes and source links for these rows were identical in substance to the
kept rows; only the wording and three scores differed (see `needs-review.md` item 5).