# Source: a folder of transcripts

The portable option. Works with any call recorder, any export, any language — and with no
integration at all. If your team already saves transcripts somewhere, you are ready.

```yaml
transcripts:
  mode: "folder"
  folder:
    path: "./transcripts"
```

## What goes in the folder

One file per call. `.md`, `.txt`, `.vtt` and `.json` all work — the agent reads whatever is
there. The file path is used as the call's unique id, which is what stops a call being counted
twice, so **do not rename files after a run**.

Give each file a small header so the agent does not have to guess who was in the room. This is
the only convention that matters:

```markdown
---
date: 2026-03-02
title: Acme Foods — discovery call
duration_min: 34
ran_by: Dana Ruiz
participants:
  - dana.ruiz@yourcompany.example (Your Company)
  - m.hartley@acmefoods.example (Acme Foods, Plant Manager)
link: https://example.com/calls/1001        # optional, for source links in reports
---
```

`duration_min` is what makes the time-saved figure a measurement instead of a guess — it is the real length of the call. If you omit it, the agent falls back to the estimate in config and the reports say so.

The email domains are what let the agent separate your people from the customer's, which drives
the internal-vs-external filter and the Prospect / Implementation / Customer classification. If
you cannot supply emails, write the company name next to each person and the agent will infer.

No header at all still works — the agent falls back to the filename and the transcript's own
content — but expect it to escalate more calls to you as unclear, which is the correct
behaviour when it genuinely cannot tell.

Everything else is free-form. Timestamps, speaker labels and formatting are all optional; a
plain wall of text is fine. See `example-run/transcripts/` for five worked examples, including
one in German.

## Getting transcripts into the folder

However you like. Some options that need no engineering:

- Export from your recorder's web UI and drop the files in.
- Point the folder at a synced directory (Drive, Dropbox, OneDrive) that someone drops files into.
- A scheduled export script, if your recorder has an API.

The system does not care how files arrive. It only cares that a call which has already been
processed is not processed again, and the ledger handles that.

## When to switch

Move to a direct connector (`sources/call-recorder-mcp.md`) when dropping files becomes the
thing you forget to do. Until then this mode is not a downgrade — it is the same system with
one fewer moving part.
