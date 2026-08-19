# Decisions log

Why this is shaped the way it is. Each entry records what was chosen, what was genuinely considered,
and what the choice costs — because the cost is the part that tells you whether to copy it.

This log starts partway through the project's life. Earlier reasoning is written into
[`README.md`](README.md) and [`docs/architecture.md`](docs/architecture.md) rather than here; these
entries are the ones where the alternative was live and the wrong choice had already been made once.

**Note on names.** Every company, person and quote in this repo is invented. Nothing here is drawn
from a real call.

**Scope note:** This log includes decisions from both the public clean-room implementation and the
live internal workflow that inspired it. Entries that could reasonably imply a public capability
state whether the safeguard is **implemented here**, provided as **guidance rather than
enforcement**, or documented as a **production lesson only**.

---

## 1. A ledger stops double-counting, not double-running

**Chose:** an atomic lock around the whole daily run, holding the owner's PID, released on exit.
A second run that finds a live owner logs the collision and exits zero without writing anything.
A second run that finds a dead owner reclaims the lock and says so.

**Considered:** relying on the ledger, which already makes runs safe to repeat. Also considered
widening the gap between the scheduled runs so an overlap becomes unlikely.

**Why:** the ledger and the lock answer different questions, and the first sounds like it covers the
second. Idempotence protects the *record*. It protects nothing that happens before the record is
written — and two overlapping runs both read the ledger before either writes it, so both conclude
the day is unprocessed, then write the same workbook from two processes and send the same messages
twice.

Widening the gap is the clock fix again: it makes the collision less likely and never impossible,
and it fails on exactly the mornings the first run overran — which is to say, the mornings something
was already wrong.

The PID matters as much as the lock. A lock that outlives its holder is an outage: refusing forever
on a stale directory turns a crash into a permanent failure, which is a worse bug than the one being
fixed. `mkdir` is the primitive because it is atomic on every POSIX filesystem, where `flock` is
absent from stock macOS and unreliable over network mounts.

**What prompted it.** A catch-up run started by hand was still working when the scheduler fired the
regular run an hour later. Nothing prevented it. The second run inspected the ledger, noticed the day
was already done and aborted itself — judgement standing in for a lock, on a day it happened to
reason well. The file's own header had described it as "safe to run by hand at any time — the ledger
prevents double-counting," which was true and was answering a different question.

**The generalisation:** *idempotent and mutually exclusive are different guarantees, and the second
sounds like a consequence of the first.* Anything that says "safe to re-run" is making a claim about
the record, not about concurrency, and the gap between those two is invisible until two copies run
at once.

**Implementation status:** Implemented in `scripts/run_daily.sh`, including stale-lock reclamation. This repository has no test suite, so the behaviour is documented rather than regression-tested here.

---

## 2. If a guard matters, something must fail when it is missing

**Chose:** a guard is wired at the point it protects, and its absence has to be detectable — not left
as a file somebody remembers connecting.

**Considered:** writing the check and connecting it later, which is what actually happened.

**Why:** a preflight check existed for five days. It was built for one purpose — turn an hour-long
hang into a fifteen-second abort when an upstream dependency is reachable but not authorised — and no
runner ever invoked it. It sat in the directory through four more hangs while the exact failure it
prevents kept costing a morning each time.

Nothing detects this state. The file is present, the logic is right, its tests pass, and it is dead
code. There is no linter for *this safeguard is not attached to anything*, and no failing test,
because a guard that is never called never fails.

The subtler cost is that writing it feels like fixing it. The problem was understood, the solution was
correct, and the incident recurred four times — which from outside is indistinguishable from never
having diagnosed it.

**The generalisation:** *a safeguard nothing depends on is indistinguishable from one that was never
written — except that it feels like the problem is solved.* The only durable evidence a guard is wired
is that removing it breaks something.

**Implementation status:** Production lesson only. The upstream-authorisation preflight described here is not included in this public template.

---

## 3. Every mirrored reference carries its own refresh rule

**Chose:** any local copy of an upstream document carries a `Refreshed:` date and a rule for when to
re-read it, and the job that owns the refresh is named. A copy without both is not a mirror.

**Considered:** refreshing on a schedule from outside the files, and refreshing by hand when someone
notices.

**Why:** one cached reference had a freshness rule and honoured it. The reference files sitting beside
it had none, and were weeks behind while every run still cited them as authoritative. The worst case
was the document *most* likely to change: one edited by hand, upstream, by people with no idea a
pipeline depended on it.

Refreshing by hand fails for the reason all by-hand steps fail — the person who would notice is the
person reading the output, and the output looks fine. Scheduling from outside is better and still puts
the rule somewhere other than the file it governs, so a new copy inherits nothing.

**The generalisation:** *a stale source raises no error.* The run succeeds, the output is confident,
well-formatted and correctly sourced — and out of date. Every quality signal you would normally check
still looks good, which makes it the hardest kind of wrong to notice and the easiest to keep shipping.

**Implementation status:** Implemented here for the configured product-knowledge cache, through `refresh_days` in `config.example.yml` and the `Refreshed:` rule in `prompts/daily.md`. The broader claim — that *every* mirrored reference carries its own named owner and refresh rule — is a production lesson. Note also that the safeguard is prompt-driven rather than a deterministic freshness validator.
