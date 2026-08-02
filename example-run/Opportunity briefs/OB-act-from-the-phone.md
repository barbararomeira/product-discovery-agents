# Opportunity brief: Act on a stop from the phone, not just see it
Status: DRAFT — auto-generated 2026-08-02, awaiting review

## Problem

Supervisors who spend the shift on the floor have no workstation. The committed **Mobile layout
(Q3)** gives them the dashboard on their phone, and Alex Kim confirmed on 2026-08-02 that it is
**view-only**. That closes the seeing half of the problem and leaves the acting half open: the
same person who now sees that line one is down still has to walk to a computer to tag the stop,
pick a reason, or record what they did about it.

This matters because Acme Foods' pilot is not scored on looking. It is scored on doing. The test
they set in the first discovery call was "supervisors act on something during the shift, at least
twice a week, without me telling them to" — and six weeks in, the line that fails that test is
precisely the line whose supervisor does not sit at a computer. A read-only phone screen tells
that supervisor what is wrong. It does not let them close the loop where they are standing.

## Who's asking

**Acme Foods** — live customer (pilot, second line) · stated importance **2** · audience: Customer
M. Hartley, Plant Manager

> "If my supervisors act on something during the shift, at least twice a week, without me telling
> them to. That is the whole test."
> — 2026-03-02, discovery call · https://example.com/calls/1001

> "We are there on line three. Not on line one, because line one's supervisor does not sit at a
> computer."
> — 2026-03-05, pilot review, answering "where are we against the test you set — supervisors
> acting during the shift, twice a week, unprompted?" · https://example.com/calls/1005

**Vertex Motors** — prospect, deal in flight · stated importance **2** · audience: Prospect
R. Adeyemi, Operations

> "Half my supervisors do not sit at a desk. They have a phone in their pocket and that is it. If
> they cannot see the line status on that phone, they will not use this, no matter how good it is."
> — 2026-03-03, demo and technical review · https://example.com/calls/1002

Counter-evidence from the same account, on the same call, immediately after being told mobile
would be read-only to start:

> "Read-only is fine. Seeing is the whole job."
> — R. Adeyemi, 2026-03-03 · https://example.com/calls/1002

Read this honestly: Vertex's importance 2 sizes the population of supervisors who will never use a
desktop. It is not, on the record, a request to act from the phone. Acme is the only account that
has attached a consequence to acting.

## Evidence

| | |
|---|---|
| Mentions | 2 (Acme Foods discovery 1001 · Vertex Motors demo 1002) |
| First seen → last mentioned | 2026-03-02 → 2026-03-03 |
| Current rank / priority | **1** / **8** — (2 + 2) × 2, joint-highest in the matrix |
| Type / roadmap status | Enhancement — Gap · Not planned (Q3 mobile layout is view-only) |
| Trend | New row, created 2026-08-02 by splitting rank 1. No prior rank to move from. |

A third touch sits on the parent row rather than here: Acme returned to the criterion on
2026-03-05 (call 1005), which is logged against "Read-only view of line status on a phone". Counted
strictly, this row has two mentions from two accounts, both at importance 2 — which is exactly the
brief threshold (importance 2 from 2+ accounts), met on the nose and not by a margin.

The 2026-W31 digest predicted this row before it existed: "if Mobile layout Q3 is view-only, the
'act on the floor' half becomes an Enhancement — Gap with no home and drafts immediately."

## Roadmap fit

There is no home for it today.

- **Mobile layout (Q3), committed** — read-only, ruled view-only by Alex Kim on 2026-08-02. It
  covers the sibling row, not this one.
- **Real-time alerts (Q2), committed** — pushes a message when a line drifts for 10+ minutes. It
  makes the gap sharper rather than smaller: the alert reaches a phone that cannot respond to it.
  Lumen Devices has already asked for those alerts in Teams "because nobody here reads email during
  the shift" (call 1004) — same floor, same person, same dead end at the point of action.
- **Downtime log, shipped** — the place the action would land. Operators already tag a stop with a
  reason code from a fixed list, so the write path exists; it is only unreachable from a phone.
- **Parking lot** — no conflict. On-premise, Public API and the custom report builder are unrelated.

One dependency worth naming: the action is only useful if the reason code the supervisor needs
exists in the list. Acme's CI lead cannot edit that list today (rank 4, Not planned, Acme's own
words: "Half the stops get logged as 'other'"). Shipping tagging-from-phone on a stale list moves
the "other" problem onto a smaller screen.

## Possible scope — smallest testable version

One action, on the stop that is already open, on the phone.

- On the read-only mobile line view, a stop that is currently open gets a single control: set its
  reason code from the existing list.
- Nothing else. No editing past stops, no free text, no new screen, no notifications, no
  permissions work beyond the existing supervisor role.
- Ships inside the Q3 Mobile layout work rather than beside it.

How we would know it worked: Acme Foods, line one, one supervisor, four weeks. The measure is
already agreed and already being reported against — does line one start meeting "acts on something
during the shift, twice a week, unprompted", the way line three does? If tagging from the phone
does not move that number, acting from the phone is not the constraint and this row should be
parked rather than grown.

## Possible scope — fuller version later

- Acknowledge or dismiss a real-time alert from the phone, so the Q2 alert has a reply path. Pairs
  directly with Lumen's Teams request.
- A short free-text note on a stop — "waiting on maintenance", "changeover ran long" — which is
  what supervisors currently tell someone verbally and nobody records.
- Reassign or escalate a stop to maintenance from the floor.
- Editable reason codes (rank 4) as a prerequisite, so the code they need is actually there.

## Open questions / discovery gaps

Two calls decide whether this is a PRD or a park. Both accounts already have an owner and a next
call.

**Acme Foods (Sam Whitfield)**
1. When line one's supervisor sees a stop on the phone, what is the *first thing* they do — tag it,
   radio someone, or walk to the machine? We are assuming tagging; that assumption is untested.
2. Does that supervisor carry a phone that can reach our product during the shift at all, or is the
   constraint the device rather than the screen?
3. If tagging from the phone existed on line one, would you expect the twice-a-week criterion to be
   met — or is something else in the way?

**Vertex Motors (Tom Becker)**
4. You said read-only was fine and that seeing is the whole job. Was that about the demo, or about
   the job? What happens on your floor between a supervisor seeing a stop and it being recorded?
5. How many of your supervisors have no workstation at all?

**For the roadmap**
6. Can one write action fit inside the Q3 Mobile layout commitment without moving its date? The
   answer changes this from a new item into a scope amendment.

## Recommendation

**Run discovery** — do not promote to PRD yet. The row clears the evidence threshold arithmetically
(importance 2 from two accounts), but only one of those accounts has actually asked to act: Vertex
supplies the population and, asked directly, said seeing was enough. That is a one-account problem
wearing a two-account number, and writing a PRD on it would be over-reading our own matrix. The
five questions above are answerable on calls that are already scheduled, and the smallest version
is small enough to land inside a Q3 commitment that is already funded — so the cost of waiting two
weeks for a real answer is close to zero, and the cost of being wrong is a mobile release that
still does not move Acme's pilot criterion.

## Update log

- **2026-08-02** — Created. Alex Kim ruled that the committed Mobile layout (Q3) is view-only and
  does not cover acting on the floor (needs-review.md item 4, raised 2026-08-02, closed the same
  day). Rank 1 "Line status on a phone" was split: the validated half stays as Roadmap validation
  against Mobile layout Q3 (now rank 2), and this open half was created as Enhancement — Gap with
  no roadmap home, priority 8. Drafted by the weekly run; no human edits exist in this file yet.
