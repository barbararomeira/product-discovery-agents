# The routine

The system produces. You decide. This page is the part most people skip, and it is the part
that determines whether the backlog is alive in three months or abandoned.

**Total cost: about 15 minutes a week, plus 30 minutes on Monday.**

---

## Daily — 2 minutes, coffee-level attention

Open the briefing when it lands. You are scanning for **three things only**:

1. **The "Needs your call" box.** Answer it the same day if you can, while the call is still
   fresh in your head and before the classification hardens into the matrix.
2. **Any bug tied to a renewal or an open deal.** Everything else in that list can wait.
3. **Anything that makes you say "wait, we promised what?"** — a commitment made to a customer
   that the roadmap does not back.

Then close it. **Do not study it.** If nothing jumps out, you are done; the matrix absorbed
everything either way. The briefing is a filter, not homework.

## Monday — 20 to 30 minutes, the real session

**Why Monday and not Friday.** The daily agent reads *yesterday's* calls, so a digest that runs on
Friday has only ever seen Monday to Thursday — and it still names its file for the whole week. The
last day of the week is structurally missing from the document that claims to cover it, and nobody
notices, because a report that arrives on time looks finished. Running on Monday costs you a weekend
of delay and buys a week that is actually complete. If you do move it back inside the week, change
what the digest says it covers, so the gap is visible rather than implied.

The digest is a **working agenda, not a report to read**. Work down it:

- **Decide every row in "Decisions for you."** Promote to a PRD, run discovery, park it, or
  resolve the roadmap conflict. A row you skip twice is a row you should park explicitly.
- **Skim the movers** to feel the trend. You are looking for surprise, not detail.
- **Forward the "Questions for the next calls" to the customer-facing team.** This is the step
  that compounds: it turns sales, onboarding and CS into your discovery engine for next week,
  and it costs you one message.
- **For any opportunity brief drafted this week**: either start shaping it into a PRD, or write
  one line in it saying why you are parking it. Both are decisions. Silence is not.

## Monthly and quarterly — bring the matrix, not your memory

In roadmap reviews and planning, filter the matrix:

- `Not planned`, sorted by priority → **your candidate list**, ranked by evidence.
- `On roadmap` with high evidence → **your defence of current bets**. "This is our top item by
  evidence, across five accounts, three of whom made it a condition" is a different conversation
  from "customers seem to want it."
- For effort discussions: bring the top rows and let engineering add effort **in the meeting**.
  Evidence from customers, effort from the people who will build it, decision from you. That
  separation is deliberate — see the README on why effort estimates were removed from scoring.

## Event-driven — 1 minute

- **Before a big account call**: filter the Customers column for that account. You get everything
  they have asked for and how strongly, instantly.
- **Before a QBR or a board update**: the roadmap-validation counts and the evidence-quality
  metric are ready-made slides.

---

## Two habits that keep it honest

1. **Answer "Needs your call" items within a couple of days.** Unresolved ambiguity quietly
   degrades the matrix, and the weekly digest will start flagging anything open two weeks as
   stale. A stale question is a decision you already made by not making it.
2. **When you disagree with a score or a classification, edit the cell.** Not in your head, not
   in a side note — in the file. Your edit is permanent, agents never overwrite it, and it stops
   a wrong pattern from accumulating across weeks.

## Two things not to do

- **Do not re-read the whole matrix daily.** That is precisely what the briefing distills. The
  matrix is for deciding, not for monitoring.
- **Do not treat Priority as an instruction.** It is evidence-weight, not strategy. A signal at
  48 with a huge build cost can absolutely lose to one at 12 that ships next sprint. The system
  tells you what customers said and how often. What to build is still your job — deliberately.

---

## When it goes quiet

If a week passes with no briefing, something broke and you may not notice — an automation that
fails silently is worse than one that fails loudly. Check `output/logs/failures.log` first. The
runner is built to abort cleanly rather than write half a result, and nothing is lost when a run
is skipped: the ledger means the next successful run picks up every call that was missed.
