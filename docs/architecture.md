# How the multi-agent system works

Two scheduled agents, a fan-out of short-lived helpers, and one file that accumulates.
Everything below is rendered by GitHub — no images to keep in sync.

---

## Who does what

| | Cadence | Model | Job | Never does |
|---|---|---|---|---|
| **Agent 1 — Discovery** | daily | **Opus 5** — judgement, and the merge is irreversible | Classify each call, judge each signal against the roadmap, merge into the matrix, write the briefing | read a transcript itself; guess when unsure |
| **Transcript helpers** | one per call, ≤5 at a time | **Sonnet 5** — long input, mechanical extraction, runs ~250×/year | Read one transcript, translate, return signals + importance + one quote each | write to the matrix or make a classification decision |
| **Agent 2 — Synthesis** | weekly | **Opus 5** — decisions someone will act on | Compare to last week, decide what crossed the threshold, draft briefs, write the digest | touch the ledger or re-extract from calls |
| **You** | 2 min daily · 30 min Friday | — | Resolve open questions, promote or park, forward the questions to the team | get asked to read the matrix end to end |

The model split is deliberate: the cheap model does the reading, the strong model makes the two
decisions that are hard to undo — what a signal means, and whether it is the same need as an
existing row. Set them in `config.yml` under `models:`. If you move the coordinator down to save
cost, the failure mode to watch for is near-duplicate rows appearing in the matrix; it shows up
within a week.

**Outputs, one line each.** Daily briefing = what was said yesterday and what needs you today.
Signal matrix = the accumulated evidence, one row per need. Weekly digest = this week's decisions.
Opportunity brief = the seed of a PRD, drafted only when the evidence justifies it.
`needs-review.md` = everything the agents refused to guess.

## The whole system

```mermaid
flowchart TB
    T["📞 Call transcripts<br/><i>folder of files, or a connector</i>"]
    R["🗺️ Your roadmap<br/><i>shipped · committed · discovery · parked</i>"]

    subgraph DAILY ["Agent 1 — daily"]
        direction TB
        C["Coordinator<br/><b>never reads a transcript</b>"]
        H1["helper"]:::h
        H2["helper"]:::h
        H3["helper"]:::h
        M["Merge<br/><b>the irreversible step</b>"]
        C -->|"one call each, max 5 at a time"| H1
        C --> H2
        C --> H3
        H1 -->|"signals + quotes<br/>+ stated importance"| M
        H2 --> M
        H3 --> M
    end

    MX[("📊 Signal matrix<br/><i>one row per need,<br/>never rebuilt</i>")]
    BR["📄 Daily briefing"]

    subgraph WEEKLY ["Agent 2 — weekly"]
        direction TB
        S["Compare to last<br/>week's snapshot"] --> D["Decisions · retention risks<br/>· questions for the team"]
        D --> OB["Opportunity briefs<br/><i>only past the evidence threshold</i>"]
    end

    DG["📄 Weekly digest"]
    PM(["🧑 You<br/>decide · resolve · forward"])

    T --> C
    R -.->|"classify against<br/>what you already plan"| M
    M --> MX
    M --> BR
    MX --> S
    D --> DG
    OB --> DG
    BR --> PM
    DG --> PM
    PM -->|"edits are final,<br/>never overwritten"| MX
    PM -->|"questions to ask"| T

    classDef h fill:#eef3f8,stroke:#94a9bd,color:#33475b,font-size:11px;
    style DAILY fill:#f7f9fb,stroke:#47809E
    style WEEKLY fill:#f5faf8,stroke:#75905A
    style MX fill:#fff8e8,stroke:#b98b2e
    style PM fill:#eef3f8,stroke:#47809E
```

The loop closes through you, and that is the point: the system prepares decisions, it does not make
them. The arrow back to transcripts is the one that compounds — the questions the digest hands you
become next week's calls.

---

## A daily run, step by step

```mermaid
sequenceDiagram
    autonumber
    participant S as Scheduler
    participant C as Coordinator
    participant L as Ledger<br/>(in the matrix)
    participant H as Helpers (parallel)
    participant M as Matrix
    participant P as PM

    S->>C: run
    C->>C: verify it can really READ the output folder
    Note over C: a scheduler that cannot read its own folder<br/>fails silently every morning — so check first
    C->>L: which of the last 7 days' calls are new?
    L-->>C: unprocessed calls only
    C->>H: one call each, ≤5 at a time
    Note over H: helpers read transcripts, translate,<br/>extract signals + quotes + importance
    H-->>C: structured findings
    C->>C: classify against the roadmap
    alt confident
        C->>M: merge into an existing row, or add a new one
    else genuinely unsure
        C->>P: "Unclear — needs you" + what would resolve it
        Note over C,P: never guess: a quietly mis-classified<br/>backlog is worse than none
    end
    C->>M: recompute priority, re-rank
    C->>L: log every processed call
    C->>P: daily briefing (PDF)
```

---

## How a signal is scored

```mermaid
flowchart LR
    Q["What the customer<br/>actually said"] --> K{"Is a consequence<br/>attached?"}
    K -->|"deal condition · success criterion<br/>· hard constraint · quantified pain<br/>· renewal risk"| TWO["importance <b>2</b>"]
    K -->|"asked · liked it ·<br/>'would be nice'"| ONE["importance <b>1</b>"]
    TWO --> SUM["Σ importances<br/>across accounts"]
    ONE --> SUM
    MEN["Mentions<br/><i>calls that raised it</i>"] --> PRI
    SUM --> PRI(["<b>Priority = Σ importances × mentions</b>"])
    PRI --> NOTE["Nothing estimated by an agent.<br/>Effort is a conversation with engineering."]

    style PRI fill:#fff8e8,stroke:#b98b2e
    style NOTE fill:#f7f9fb,stroke:#94a9bd,color:#33475b
```

---

## Why the merge is guarded

The merge decides whether a new signal is *the same need* as an existing row. It is the only step
that can silently corrupt the evidence base, and it fails in two directions:

```mermaid
flowchart TB
    N["New signal arrives"] --> J{"Same underlying need<br/>as an existing row?"}
    J -->|"wrongly says NO"| A["Two rows for one need<br/>2 + 2 instead of 4<br/><i>never surfaces</i>"]:::bad
    J -->|"wrongly says YES"| B["Two needs in one row<br/>count is a lie<br/><i>you act on a phantom</i>"]:::bad
    J -->|"confident"| G["One row, evidence accumulates"]:::good
    J -->|"close call"| E["Keep separate + ask the PM"]:::ok

    classDef bad fill:#fdeceb,stroke:#C4718D,color:#7a1b14;
    classDef good fill:#eef7f2,stroke:#75905A,color:#2b5245;
    classDef ok fill:#eef3f8,stroke:#47809E,color:#28405c;
```

That is why the merge stays with the strongest model, never gets delegated to a helper, and prefers
"keep them separate and ask" over a confident guess.

---

## What makes runs safe to repeat

```mermaid
flowchart LR
    A["Run starts"] --> B["Look back 7 days"]
    B --> C{"Already in<br/>the ledger?"}
    C -->|yes| D["Skip"]
    C -->|no| E["Process"]
    E --> F["Append to ledger"]
    F --> G["Matrix updated"]

    style G fill:#fff8e8,stroke:#b98b2e
```

Two consequences worth knowing: you can run it by hand any time without double-counting anything,
and a missed day — laptop asleep, scheduler broken, a call skipped — heals itself on the next run
rather than being lost.

### Repeatable is not the same as concurrent

The ledger makes a run safe to *repeat*. It does nothing to make two runs safe to *overlap*, and
those are different guarantees that are easy to confuse — the second sounds like a consequence of
the first and is not.

Overlapping runs share a failure the ledger cannot see: both read it before either writes it, so
both conclude the day is unprocessed, and both go on to write the same workbook from two processes
and deliver the same messages twice. Idempotence protects the *record*; it protects nothing that
happens before the record is written.

This is not theoretical. A catch-up run started by hand was still working when the scheduler fired
the regular run an hour later. Nothing prevented it. The second run happened to inspect the ledger,
notice the day was already done and abort itself — judgement standing in for a lock, on a day it
happened to reason well.

```mermaid
flowchart TD
    A["Run starts"] --> B{"mkdir lock<br/>succeeds?"}
    B -->|yes| C["Own the day:<br/>write pid, trap EXIT"]
    B -->|no| D{"pid still<br/>alive?"}
    D -->|yes| E["Abort, exit 0<br/>no writes"]
    D -->|no| F["Stale lock:<br/>reclaim and log"]
    F --> C
    C --> G["Run, then release"]

    style E fill:#f6f6f6,stroke:#999
    style G fill:#fff8e8,stroke:#b98b2e
```

`mkdir` is the lock because it is atomic on every POSIX filesystem, which `flock` is not — absent
from stock macOS, unreliable over network mounts. The PID inside distinguishes a live run from a
crashed one, because **a lock that outlives its holder is an outage**: refusing forever on a stale
directory turns a crash into a permanent failure, which is a worse bug than the one being fixed.

### Two guard failures worth designing against

**A guard that is written but never called.** A preflight check existed for five days — built
specifically to turn an hour-long hang into a fifteen-second abort — and no runner ever invoked it.
It sat in the directory through four more hangs while the thing it prevented kept happening. Nothing
detects this: the file is present, it is correct, its tests pass, and it is dead code. If a guard
matters, something must fail when it is missing; otherwise the only evidence it is wired is that
somebody remembers wiring it.

**A reference that goes stale without saying so.** The knowledge cache above carries a freshness
rule. The reference files beside it did not, and sat weeks behind while every run still cited them
as authoritative. The worst case was the one most likely to change: a document edited by hand,
upstream, by people with no idea a pipeline depended on it.

The rule that falls out: **every mirrored reference carries its own `Refreshed:` date and its own
rule, or it is not a mirror — it is a copy that was accurate once.** A stale source raises no error.
It produces confident, well-formatted, sourced output that is out of date, which is the hardest kind
of wrong to notice.
