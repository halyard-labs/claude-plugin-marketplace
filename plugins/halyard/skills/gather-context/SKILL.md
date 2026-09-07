---
name: gather-context
description: >-
  Gather background context before starting work or answering questions about a
  topic. Use when the user asks 'what do we know about', 'background on', 'catch
  me up on', 'context on', 'research X before starting', 'what's the history of',
  'look into', 'investigate', 'find out about', or needs orientation on an
  unfamiliar area. Also use proactively at the start of a task when the work
  touches a named system or feature area (auth, payments, ingestion, a specific
  service), requires architectural judgment, or the codebase has prior decisions
  that could constrain the approach. Skip for mechanical edits, single-file
  changes, or clear-cut bug fixes where prior context is unlikely to change
  behavior. Combines knowledge base search, codebase exploration, and web search.
---

# Gather Context

> **Tool names.** Tools are written here by their bare name (for example `search_knowledge`). The name your client exposes carries a prefix that depends on how the Halyard server was mounted: `mcp__plugin_halyard_org-kb__search_knowledge` from this plugin in Claude Code, `mcp__halyard__search_knowledge` or `mcp__ask-expert__search_knowledge` when it was added as a standalone server or claude.ai connector, and a prefix derived from the `org-kb` server key in other clients. Match on the part after the last `__`. If the exact name is not in your tool list, search the available (or deferred) tools for the bare name before concluding the tool is unavailable — a prefix mismatch is not "unavailable".

## When to use

**Use this skill when any of these apply:**

- The user explicitly asks for background, research, or a catch-up on a topic
- The task touches a named system or feature area that may have prior decisions (e.g. auth, billing, a specific pipeline, a shared library)
- The task requires architectural judgment or multi-file changes, not a mechanical edit
- You notice domain jargon, product names, or module names you don't have context on

**Skip it when:**

- The task is a mechanical edit, typo fix, or obvious single-file change
- You already have the context from the current conversation
- The user explicitly wants you to just act, not research

## Workflow

Start with knowledge base search — it's the fastest way to surface prior decisions and past work. Work outward from there:

0. **Orient (optional)** — If you're unsure who the caller is or what workspace you're in, `whoami` returns the authenticated user, their org, role, and connected integrations. Useful at the very start of a fresh session before deciding where to look.

1. **Knowledge base first** — Search for the topic area:
   ```
   search_knowledge(query: "the feature area or system")
   ```
   If results look relevant, follow up with `explore_knowledge(entry_id: "...")` to pull in connected decisions and prior work.

2. **Codebase** — Read relevant files, check `git log`/`git blame` for recent changes and who owns the area.

3. **Web** — Search externally only when the topic genuinely extends beyond the repo (third-party APIs, standards, recent releases).

If no Halyard tool exists under any prefix (server not configured, or not authenticated — check `/mcp`), rely on codebase exploration and web search. Do not treat a prefix that differs from the examples above as the tools being unavailable. Either way, synthesize findings into a brief summary (2–4 bullets) before proceeding with the task — this doubles as a sanity check that you gathered enough.
