# How the multi-agent system works

Two scheduled agents, a fan-out of short-lived helpers, and one file that accumulates.
Everything below is rendered by GitHub — no images to keep in sync.

---

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
