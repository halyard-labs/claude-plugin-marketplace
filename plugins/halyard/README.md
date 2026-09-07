# Halyard

**Shared team memory for AI agents.**

Halyard connects your agent to your organization's living knowledge graph —
past decisions, work summaries, processes, and captured Q&A — and routes
questions to the right teammate on Slack, Teams, or Discord when the answer
isn't written down yet.

With the Halyard plugin installed, the agent will:

- **Search before it guesses.** Prior decisions, specs, and "we already tried
  this" findings surface before the agent plans new work.
- **Ask a human when it should.** On a knowledge-base miss, the agent routes
  the question to the right expert on Slack, waits for the reply, and keeps
  working.
- **Capture answers once.** Helpful replies are summarized back into the
  knowledge base, so the same question never gets asked twice.
- **Log work as it ships.** Decisions and outcomes from each session become
  searchable context for every future agent — and every future hire.

## What's included

- **`org-kb` MCP server** — hosted at `mcp.usehalyard.ai`. OAuth on first
  use: the agent's first Halyard tool call opens a browser to authorize
  against your Halyard account. No API keys to paste, no secrets to configure.
- **Seven skills** that teach the agent when to search, when to ask, and what
  to write back:
  - `gather-context` — orient on prior decisions before starting work
  - `ask-for-help` — route questions to human experts and capture answers
  - `log-work` — record decisions and outcomes to the knowledge base
  - `review-work` — standups, catch-ups, and delivery analytics
  - `triage-knowledge` — review the knowledge-base inbox queue
  - `mark-terms` — link org jargon to canonical definitions
  - `setup-cli` — install, authenticate, and verify the `halyard` CLI
- **`knowledge-first` rule** (Cursor) — orients every session toward the
  knowledge base: search before substantive work, capture outcomes after.
- **Session hooks** (Claude Code, Codex) — nudge knowledge capture at session end, and upload the session transcript to Halyard via the `halyard` CLI when it is installed and authenticated (the `setup-cli` skill walks the agent through that).

## Tool names across clients

The default tool name is the one Claude Code gives this plugin's `org-kb` server:
`mcp__plugin_halyard_org-kb__<tool>` (for example `mcp__plugin_halyard_org-kb__search_knowledge`).
Skills, hooks and `CLAUDE.md` guidance use that form. Older connections reach the same
server under other prefixes, and they keep working as aliases:

| Surface | Tool name |
| --- | --- |
| **Default** — Claude Code, this plugin (`.mcp.json` key `org-kb`) | `mcp__plugin_halyard_org-kb__search_knowledge` |
| Alias — standalone server added as `halyard` (docs, `halyard setup`) | `mcp__halyard__search_knowledge` |
| Alias — claude.ai connector / Claude Code on the web | `mcp__halyard__…` or `mcp__ask-expert__…`, depending on the connector name |
| Alias — Codex / Cursor | derived from the `org-kb` server key by the client |

Every skill carries a short note saying the same thing, and the session hooks recognise a
search or capture made under any of these prefixes. When the default name is absent, match on
the part after the last `__` and use the alias that is present.

## Requirements

An account at [usehalyard.ai](https://usehalyard.ai) with your Slack, Teams,
or Discord workspace connected.

## Getting started

Once installed, ask the agent:

```text
Use Halyard to tell me who I am, then search the knowledge base for our most recent decision.
```

Expect a `whoami` call returning your user and organization, followed by a
`search_knowledge` call. From then on the agent searches shared memory before
starting work, asks your teammates when it's stuck, and logs what it ships.

To also upload session transcripts and scaffold Halyard for the whole repo,
ask the agent:

```text
Set up the Halyard CLI.
```

It installs `@halyard/cli`, walks you through `halyard login` (or a
`HALYARD_TOKEN` for headless use), and verifies with `halyard sync --dry-run`.

## Links

- Homepage: [usehalyard.ai](https://usehalyard.ai)
- Docs: [Connect your agent](https://usehalyard.ai/docs/connect-agent/overview/)
- Support: support@halyard.studio
