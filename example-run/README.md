# A complete worked example

Everything in this folder is **real output from a real run** — the system was pointed at the five
fake transcripts in `transcripts/` and left to work. Nothing here was written by hand to look good.

The companies are invented: **Northwind Robotics** sells shop-floor monitoring software;
**Acme Foods**, **Vertex Motors**, **Halden Pumps** and **Lumen Devices** are its customers and
prospects. Any resemblance to a real account is a coincidence.

Read this folder in the order below and you will understand the whole system in about five minutes.

---

## 1. What went in

| File | What it is |
|---|---|
| `config.yml` | The filled-in configuration for Northwind Robotics. Compare it to `config.example.yml`. |
| `knowledge/roadmap.md` | **The roadmap**, in the form the agents read: shipped · committed (with dates) · in discovery · explicitly parked. This is how a briefing can say "validates Real-time alerts, committed Q2" instead of just "customer wants alerts". |
| `transcripts/` | Five calls across one week. |

The five calls are deliberately varied, because that is what a real week looks like:

- **Acme Foods — discovery** (prospect): a plant manager who finds out he is behind at 4pm.
- **Vertex Motors — demo** (prospect): an IT lead with a hard security requirement, and an
  operations lead whose supervisors do not sit at desks.
- **Halden Pumps — rollout planning** (implementation): contract signed, now the works council
  and the admin overhead become the problem.
- **Lumen Devices — weekly** (customer, **in German**): planned maintenance being counted as a
  loss, and a promise made about a delivery date.
- **Acme Foods — pilot review** (customer): six weeks in, an honest renewal warning and a real bug.

## 2. What came out

| File | What it is |
|---|---|
| `signal-matrix.xlsx` | **The backlog.** 20 signals extracted from 5 calls, ranked by evidence. Four sheets: the signals, cross-call themes, the processed-calls ledger, and run metrics. |
| `Daily briefing/` | The two-minute morning read. |
| `Weekly digest/` | The Friday agenda: movers, decisions, retention risks, questions to send back to the team. |
| `Opportunity briefs/` | One brief, drafted the moment a human answered an open question — see §3. |
| `needs-review.md` | What the agents refused to guess about, waiting for a human. |
| `metrics.md` | What the system reports about itself: 5 calls, **2 h 44 min of real talk time** read for you — and at that rate, **7.6 working days** of customer conversation by 31 December. |
| `logs/` | What a run actually prints. |

## 3. Things worth noticing in the output

**The same need from two different accounts became one row, not two.** "A read-only view of line
status on a phone" was raised by Vertex Motors (operations lead: supervisors have a phone and
nothing else) and by Acme Foods (line one's supervisor does not sit at a computer). One row, two
accounts, two mentions — which is exactly why it ranks first. Two rows would have buried it.

**Importance is taken from consequences, not enthusiasm.** Vertex's IT lead says single sign-on is
*"a gate, not a wish"* — that is a 2. Acme's plant manager says multi-site *"is not a condition for
us, but he will ask"* — that is a 1, even though he mentioned it twice. The difference is whether
anything hangs on it.

**Audience separates upside from risk.** Look at the Audience column. Signals marked `Customer`
come from accounts that already pay you. Acme's warning that they will *"struggle to defend the
renewal"* if the reason-code list stays frozen is not a feature request, it is churn risk with a
date on it.

**A promise got caught.** In the German call, Northwind's own account manager confirms a delivery
month for shift comparison. In the Acme review, the plant manager admits he told his boss multi-site
was "coming later this year" — and is corrected on the call, because multi-site is only in
discovery. The system surfaces both, because it knows what the roadmap actually says.

**The German call was analysed in German and reported in English.** No translation step, no
separate configuration. Same for any other language.

**Bugs are tracked but kept in their place.** Two real bugs appear (a filter that resets, and output
double-counted after a line restart). They are in the matrix because recurrence is signal, but they
never trigger an opportunity brief — they belong in your bug tracker, not your discovery backlog.

**The agents escalated instead of guessing.** See `needs-review.md`. That is the system working
correctly: a backlog quietly mis-classified is worse than no backlog, because you would trust it.

**A human answer unlocked a brief.** The digest predicted it explicitly: *"if Mobile layout Q3 is
view-only, the 'act on the floor' half becomes an Enhancement — Gap with no home and drafts
immediately."* Alex ruled that Q3 is view-only, the top row was split into the validated part and
the open part, and `Opportunity briefs/OB-act-from-the-phone.md` drafted itself against two accounts
at importance 2. That is the whole loop in one move: agent asks, human decides, backlog updates.

## 4. Reproduce it yourself

```bash
cd example-run
CONFIG="$PWD/config.yml" ../scripts/run_daily.sh
CONFIG="$PWD/config.yml" ../scripts/run_weekly.sh
```

Run the daily twice and watch nothing get double-counted — the ledger in the matrix is what makes
runs safe to repeat and missed days self-healing.

Then swap `transcripts/` for a few of your own calls, edit `knowledge/roadmap.md` to describe your
product, and you have your own version. That is genuinely the whole setup.
