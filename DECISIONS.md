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

**Implementation status:** Implemented in `scripts/run_daily.sh`, including stale-lock reclamation, and regression-tested in `tests/test_run_lock.py` — which lifts the lock block out of the shipped script rather than copying it, so the tests fail if the real one changes.

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

---

## 4. You cannot test a judgement, but you can check its output

**Chose:** a deterministic validator that runs over the matrix immediately after the agent writes it
(`tools/validate_matrix.py`, wired into `scripts/run_daily.sh`). It re-derives every rule that has a
single right answer: importance inside the stated scale, each account counted once, priority equal to
its own published formula, ranks 1..n in priority order, every row citing a source call, and the
PM-owned columns identical to a snapshot taken before the run.

**Considered:** unit tests over the merge, which is what a reviewer naturally asks for. Also
considered leaving the rules as prompt instructions and trusting the model to follow them, which is
what the system did before.

**Why:** the merge is the judgement. Deciding that two customers described the same underlying need
is the one thing here that a model does and rules cannot, and there is no function to test — writing
one would mean building a merge engine that should not exist, then testing that instead of the thing
that actually runs.

What escapes that argument is everything *downstream* of the judgement. Whether importance is 1 or 2
is semantic; whether the recorded value is *inside the scale* is arithmetic. Whether two requests are
the same need is semantic; whether one account got counted twice in a single cell is set membership.
The prompt states all of these plainly, and a prompt is not an enforcement mechanism — the difference
only shows up when a run mis-parses a cell or silently renumbers a rank, and produces a matrix that
looks finished and is wrong.

The manual-column check is the one that matters most and is easiest to miss. A run legitimately
re-ranks and re-evidences a row; it must never re-own one. Distinguishing "the agent overwrote a
human's column" from "the human changed it themselves" is impossible after the fact without a
before-snapshot, so the runner takes one.

Failing the run outright was rejected: by the time validation happens the briefing is written and is
worth having. It notifies instead, loudly.

**The generalisation:** *the parts of an AI system you cannot test are usually surrounded by parts
you can.* Reaching for determinism in the model's own reasoning gets you a worse system and a false
sense of coverage; reaching for it at the boundary — the shape, arithmetic and provenance of what the
model produced — gets you a real check that fails the same way every time. Ask what the output must
be true of, not what the reasoning should have been.

**When to remove it.** A check earns its place by being believed, so the condition to watch is false
positives — not effort. If it starts failing runs that turn out to be fine (a legitimate merge it
reads as a duplicate account, a rank order it disputes for a reason the prompt actually allows), it
has become the thing it was built to prevent: an alarm that costs attention and does not repay it,
and the next real failure gets scrolled past with the rest. Fix the rule if the rule is wrong; delete
the check if it cannot be made right. What is *not* a reason to remove it is that it was cheap to
write — it costs nothing to keep, and the question of whether it was worth starting stopped being
live the moment it existed.

**Implementation status:** Implemented in `tools/validate_matrix.py`, wired into
`scripts/run_daily.sh`, and covered by `tests/test_validate_matrix.py`.

---

## 5. A weekly report cannot cover a week that has not finished

**Chose:** run the weekly digest on **Monday**, reporting the ISO week that has just ended, and
resolve that week from the day before the run rather than from the run's own date.

**Considered:** leaving it on Friday and simply printing the true coverage in the header, so the
gap is disclosed rather than removed. Also considered running it late on Sunday, which covers the
week but puts an automated job in the one window nobody is watching.

**Why:** the daily agent reads *yesterday's* calls. A weekly that fires midday on Friday has
therefore only ever seen Monday to Thursday, and a weekly that fires late on Friday has still not
seen that day's calls. Either way it is named for a week whose last day it structurally cannot
contain. This is not a rare edge: it is every single run, and the last day of a week is not a quiet
one. The failure is invisible in the worst way — the report arrives on schedule, the numbers are
internally consistent, and nothing anywhere says a fifth of the week is missing. It surfaced only
when a reader compared two editions of the same week and found one covering three days and the
other covering seven.

Disclosure was rejected as the primary fix. A header reading "calls of the 10th to the 12th" on a
document titled with the whole week is honest, and it is still a document that answers the wrong
question — the reader wants the week, and no amount of accurate labelling supplies the two days
that were never read.

**What it costs:** the digest arrives after the weekend rather than before it, so a decision it
would have prompted on Friday afternoon waits until Monday. That is a real cost and worth stating
plainly: this trades latency for completeness. Take the other side of the trade if your week's
decisions genuinely cannot wait — but then change what the digest claims to cover, so the missing
days are visible rather than implied.

**The trap that comes with the fix.** A Monday belongs to the *new* ISO week. A run that resolves
its reporting period from its own date will name the file for a week that is one day old, and it
will do this correctly-looking every time. Resolve from the day before the run — the Sunday that
just ended — and the week number falls out right. `config.example.yml` ships `weekly_weekday: 1`
for this reason, and `templates/cron.md` matches it.

**The generalisation:** *a report's name is a claim about coverage, and the schedule either honours
it or quietly breaks it.* Any recurring summary whose inputs lag by a day cannot run inside the
period it summarises. The question to ask of any scheduled report is not "when is this convenient
to read" but "by the time this fires, has everything it claims to describe actually arrived".

**Implementation status:** Implemented here as configuration and documentation —
`config.example.yml` and `templates/cron.md` ship the Monday schedule, and
[`docs/pm-routine.md`](docs/pm-routine.md) states the reasoning. The backwards week resolution is
**guidance rather than enforcement**: nothing in this repo fails a run whose digest is named for the
week it is running in. Production lesson.
