# Needs review — Alex Kim

Rows where the agent refused to guess. Edit the value in `signal-matrix.xlsx` directly;
a human decision is final and is never overwritten by a later run.

## 2026-08-02

### 1. Alerts delivered into the chat tool people use on shift
- **Field left open:** Roadmap status — `Unclear — needs Alex Kim`
- **What is unclear:** Real-time alerts is committed for Q2, but the roadmap note does not say
  which delivery channels are in scope. If Teams delivery is already inside that commitment this
  is a `Roadmap validation` row; if not, it is separate work and stays `New feature`.
- **What would resolve it:** the Q2 alerts scope — does it include chat delivery, or email only?
- Raised by Lumen Devices (importance 2), Marc Olsen, 2026-03-04 — https://example.com/calls/1004

### 2. Create and remove users in bulk
- **Field left open:** Roadmap status — `Unclear — needs Alex Kim`
- **What is unclear:** whether the committed Q3 SSO/SAML work also brings directory-driven
  provisioning and deprovisioning. If it does, Halden's problem disappears in Q3; if SAML is
  authentication only, bulk import is a separate, unplanned item they need before rollout.
- **What would resolve it:** confirm whether SCIM / directory sync is in the Q3 SSO scope.
- Raised by Halden Pumps (importance 2), Priya Nair, 2026-03-03 — https://example.com/calls/1003

### 3. Two rows kept separate — possible single need
- **Rows:** "Separate planned maintenance from unplanned downtime" (Lumen, importance 2) and
  "Read planned stops from the maintenance system" (Lumen, importance 1)
- **What is unclear:** both came from the same call and both map to the *Maintenance-system
  integration* discovery item. One is a complaint that the availability number is wrong; the other
  proposes reading work orders as the mechanism. They were kept apart rather than fused, per the
  rule that close calls stay separate.
- **What would resolve it:** decide whether excluding planned maintenance can ship without the
  integration. If not, merge into one row and the combined priority becomes 3.

### 4. Committed mobile layout is read-only — may not cover the need it is ranked against
- **Rows:** "Line status on a phone for supervisors who have no desk" — the top-ranked row
  (Vertex Motors 2, Acme Foods 2, priority 8)
- **What is unclear:** the row is marked `On roadmap — committed (Mobile layout, Q3)`, and that
  item is read-only. But Acme Foods' pilot success criterion is supervisors *acting* during the
  shift, not only viewing. If read-only does not satisfy that criterion, the highest-priority
  row in the matrix is only partly covered by the thing it is validating.
- **What would resolve it:** confirm whether the Q3 Mobile layout includes taking action, or
  viewing only. If viewing only, this needs splitting into a validated part and an open part.
- Raised by Vertex Motors (importance 2), Tom Becker, 2026-03-03 — https://example.com/calls/1002
  and Acme Foods (importance 2), Sam Whitfield, 2026-03-05 — https://example.com/calls/1005
- **Note:** this run titles that row *"Read-only view of line status on a phone"* (rank 1,
  priority 8); its roadmap status is now `Unclear — needs Alex Kim (Mobile layout Q3 is read-only)`.

