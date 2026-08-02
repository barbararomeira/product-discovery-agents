# Source: a call recorder, connected directly

The hands-off option. The agent lists yesterday's calls and pulls each transcript itself, so
nobody has to remember to export anything.

```yaml
transcripts:
  mode: "recorder"
  recorder:
    mcp_prefix: "<your recorder's MCP tool prefix>"
    lookback_days: 7
```

## What this needs

A call recorder exposed to Claude Code as an MCP server, offering roughly:

| Capability | Used for |
|---|---|
| list meetings in a date range | finding the calls in the window |
| get meeting summary | qualifying a call cheaply, before spending a transcript read |
| get meeting transcript | the actual signal extraction |
| a stable recording id | the ledger key that prevents double-counting |

Most recording tools with an MCP server expose these under one name prefix. Set `mcp_prefix`
to it, and add the tool names to `EXTRA_ALLOWED_TOOLS` before running:

```bash
export EXTRA_ALLOWED_TOOLS="mcp__<server>__list_meetings,mcp__<server>__get_meeting_summary,mcp__<server>__get_meeting_transcript"
./scripts/run_daily.sh
```

## Worked example: Fathom

The system was originally built against Fathom, so here is that configuration concretely. Read
it as one example of the shape, not as a requirement — nothing in `prompts/` or `scripts/`
mentions any vendor.

```yaml
transcripts:
  mode: "recorder"
  recorder:
    mcp_prefix: "mcp__claude_ai_Fathom__"
    lookback_days: 7
```

```bash
export EXTRA_ALLOWED_TOOLS="mcp__claude_ai_Fathom__list_meetings,mcp__claude_ai_Fathom__get_meeting_summary,mcp__claude_ai_Fathom__get_meeting_transcript,mcp__claude_ai_Fathom__get_recording_by_call_id"
```

Notes from running this in production for a while:

- **Summaries first, transcripts second.** Summaries are short and cheap; use them to decide
  whether a call qualifies, then spend a transcript read only on calls that carry signal. The
  prompt already works this way.
- **Recording ids are the ledger key.** They are stable, unlike titles, which people rename.
- **Attendee email domains are how the internal/external split works.** If your recorder does
  not expose them, expect more calls to be escalated as unclear — which is the honest outcome.

## Any other recorder

The same four capabilities are all that is required. If your tool has an MCP server, set the
prefix and the allowed tools and it should work. If it does not, use
`sources/transcript-folder.md` — the folder mode is a first-class path, not a fallback.
