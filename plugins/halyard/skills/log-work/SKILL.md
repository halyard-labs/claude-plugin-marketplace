---
name: log-work
description: >-
  Log work to the team knowledge base — completed work at the end, and other
  work as it happens: a spec or plan before execution starts, a decision when
  it is made, a runbook or research write-up as a standalone doc. Use when
  finishing a session, completing a task, wrapping up, a plan has just been
  agreed and implementation is about to begin, making a decision, or when
  prompted to record, document, save, or summarize. Triggers on 'log this',
  'write this up', 'save to knowledge base', 'document what we did', 'record
  this decision', 'capture the spec', 'save the plan', 'summarize this
  session'. Captures specs, work summaries, architectural decisions, process
  documentation, and learnings for team visibility.
---

# Log Work

> **Tool names.** The default names below are the halyard plugin's `org-kb` server as Claude Code exposes it: `mcp__plugin_halyard_org-kb__<tool>`. Older connections expose the same server under other prefixes — `mcp__halyard__<tool>` (standalone server added by the docs or `halyard setup`) and `mcp__ask-expert__<tool>` (claude.ai connector, Claude Code on the web) — and Codex and Cursor derive their own prefix from the `org-kb` key. These are aliases for one server, so match on the part after the last `__`: if the default name is not in your tool list, use whichever alias is present (search the deferred tool list for the bare name if needed) rather than concluding the tool is unavailable.

Decide for yourself whether the session produced durable knowledge: code changes with non-obvious reasoning, a decision and its rationale, debugging findings, research conclusions, or a reusable answer from the user. If it did, call `mcp__plugin_halyard_org-kb__summarize_work` before your final response. If it did not (brief Q&A, simple file reads, casual conversation), skip logging and end the turn — do not ask the user whether to log.

When you do log, end your final message with one line the Stop hook recognises, so it does not nudge again for a session that is already captured:

```
Logged to Halyard: <entry title>
```

## What to log, and when

Completed work is the usual case, but not the only one. Log other work at the moment it exists, so the entry records what was known and believed then rather than a reconstruction after the fact:

| Moment                                          | What to log                                                        | Tool                | `entry_type`  |
| ----------------------------------------------- | ------------------------------------------------------------------ | ------------------- | ------------- |
| A plan is agreed, before implementation starts  | The spec: goal, chosen approach, alternatives rejected and why     | `upsert_knowledge`  | `SPEC`        |
| A choice between valid approaches is made       | The decision and its reasoning                                     | `summarize_work`    | `DECISION`    |
| Research or investigation concludes             | Findings, sources, what they rule in or out                        | `summarize_work`    | `CONTEXT`     |
| A procedure worth repeating is worked out       | The steps, written for the next person to follow                   | `upsert_knowledge`  | `PROCESS`     |
| Work is finished                                | What changed and why, plus reflections                             | `summarize_work`    | `WORK_OUTPUT` |

Earlier entries don't replace the final one: a spec logged before execution still needs a `WORK_OUTPUT` entry when the work is done.

## Capturing a spec before execution

When a plan has been agreed for non-trivial work — anything where a real alternative was weighed and set aside — capture it as a standalone `SPEC` doc **before** you start implementing or hand it to a subagent. Skip it for mechanical edits and one-line fixes where there was nothing to choose between.

```
mcp__plugin_halyard_org-kb__upsert_knowledge(
  title: "Spec: stateless auth for mobile clients",
  content: "## Goal\n...\n## Approach\n...\n## Alternatives considered\n- Server sessions — rejected: mobile clients can't hold cookies reliably\n## Constraints and assumptions\n...\n## Prior knowledge relied on\n- [Auth middleware decision](halyard://knowledge/ke_xyz)\n## Open questions\n...",
  entry_type: "SPEC",
  resource: "<ticket or PR URL, if one exists>",
  tags: ["auth", "spec"]
)
```

- **Write down the reasoning, not just the plan.** The alternatives rejected and the constraints that drove the choice are what a later reader can't recover from the code.
- **Cite what you relied on.** Link the KB entries, tickets, or teammate answers that shaped the approach with `halyard://` links, so the spec joins the graph.
- **Keep it point-in-time.** Don't rewrite the spec afterwards to match what shipped. If the plan changes materially mid-work, write a new `SPEC` with `supersedes_entry_id` pointing at the old one; minor drift belongs in the final `WORK_OUTPUT` entry.
- **Link the outcome back.** Keep the returned entry id and pass it as `source_knowledge_entry_id` on the closing `summarize_work`, so the spec and what actually happened sit side by side.
- Like other agent-authored entries, the spec lands in the INBOX review queue and becomes searchable once a human accepts it (see the **triage-knowledge** skill).

## Usage

```
mcp__plugin_halyard_org-kb__summarize_work(
  title: "Implemented user authentication",
  summary: "Added JWT-based auth with refresh tokens to the API. Used existing middleware pattern from request-logger. Key decision: chose JWT over sessions because mobile clients need stateless auth.",
  entry_type: "WORK_OUTPUT",
  tags: ["auth", "api", "security"]
)
```

## Parameters

| Parameter                  | Description                                                                            |
| -------------------------- | -------------------------------------------------------------------------------------- |
| `title`                    | Short title for the work entry (required)                                              |
| `summary`                  | Detailed summary of what was done and why (required)                                   |
| `entry_type`               | Type: `"WORK_OUTPUT"` (default), `"DECISION"`, `"PROCESS"`, `"CONTEXT"`, or `"SPEC"`   |
| `visibility`               | `"WORKSPACE"` (default, all org members) or `"PRIVATE"` for highly sensitive content    |
| `tags`                     | Tags for categorization                                                                |
| `knowledge_entry_id`       | ID of an existing entry to update instead of creating new                              |
| `source_provider`          | Source system: `"github"`, `"slack"`, `"linear"`, `"claude"`, `"codex"`, `"notion"`    |
| `resource`                 | Navigable link to the source material (PR, ticket, thread)                             |
| `source_knowledge_entry_id`| ID of another entry this derives from (citation chain)                                 |
| `supersedes_entry_id`      | ID of an older entry this replaces (marks it outdated)                                 |
| `session_id`               | Link this entry to a specific agent session                                            |

## Sensitive work

If the summary contains highly sensitive information — credentials context, personnel matters, security findings, unannounced plans — pass `visibility: "PRIVATE"` so the entry is born private instead of workspace-visible:

```
mcp__plugin_halyard_org-kb__summarize_work(
  title: "Rotated compromised staging credentials",
  summary: "...",
  visibility: "PRIVATE"
)
```

A PRIVATE entry is findable in search only by its author. Widen access later with `share_knowledge` (grants a specific person read access) or `set_knowledge_visibility` (changes the tier). When in doubt about sensitivity, prefer PRIVATE — widening later is easy, un-leaking is not.

## Choosing an entry type

- **`WORK_OUTPUT`** — Code changes, feature implementations, bug fixes, refactors
- **`DECISION`** — Architectural choices, design trade-offs, technology selections (include reasoning)
- **`PROCESS`** — A repeatable procedure written to be followed again: how-to docs, runbooks, setup procedures, team conventions. Not an account of the steps you performed this session — that is `WORK_OUTPUT`, however step-by-step it reads
- **`CONTEXT`** — Background research, reference material, exploratory findings
- **`SPEC`** — Plans, specifications, project descriptions
- **`DEFINITION`** — The canonical definition of a product/industry/org term (one concept per entry). See the `mark-terms` skill for when to define and how to link occurrences.

## Authoring knowledge directly

`summarize_work` is the right tool for recording work you just performed. When you instead need to author a **standalone document** — a decision record, a runbook, a spec, or a piece of reference context not tied to this session's work — use the general-purpose write verb:

```
mcp__plugin_halyard_org-kb__upsert_knowledge(
  title: "Auth token rotation runbook",
  content: "## Steps\n1. Rotate the signing key in Vault\n2. ...",
  entry_type: "PROCESS",
  tags: ["auth", "runbook"]
)
```

- Pass the **full** `title` and `content` every time — updates replace, they don't append.
- Omit `knowledge_entry_id` to create a new entry; pass an existing ID (from `search_knowledge` / `list_knowledge`) to rewrite one in place.
- `entry_type` here supports the five narrative types above plus **`CONTACT`** / **`COMPANY`** for people and orgs.
- Link people and other entries inline with `halyard://` URIs in markdown links — they're auto-resolved into mentions and citations: `[Sarah Chen](halyard://contact/ct_abc123)`, `[prior decision](halyard://knowledge/ke_xyz)`. Use `search_people` to find the right id first.
- Use `resource` for a navigable source URL, `supersedes_entry_id` when this entry replaces an older one.
- New agent-authored entries land in the **INBOX review queue** and go live once a human accepts them (see the **triage-knowledge** skill). To retire an entry, use `delete_knowledge` (archives by default, reversible).

## Attaching rich artifacts

When your work produced a self-contained report or dataset that's more useful rendered than as prose, attach it to the entry after creating it:

```
mcp__plugin_halyard_org-kb__attach_artifact(
  knowledge_entry_id: "ke_...",
  format: "HTML",      // or "CSV"
  content: "<html>...self-contained markup, inline styles only...</html>"
)
```

The entry's markdown stays the searchable description; the artifact is the rich payload shown alongside it. One artifact per entry — re-attaching replaces it. HTML renders in a script-free sandbox, so use inline styles and no `<script>` (max 5 MB).

## Reflections

When logging work, include 2-4 reflection bullets in your summary covering any of:

- **What worked** — approaches, tools, or patterns that were effective
- **What didn't** — dead ends, things that took longer than expected, or approaches to avoid
- **Learnings** — new discoveries about the codebase, tools, APIs, or setup
- **Suggestions** — improvements to code, process, config, or tooling

Be genuine, not performative. Skip a category if nothing meaningful to say. Be specific — "Grep was faster than Agent for finding the config" beats "tools worked well." If the session was straightforward, a single bullet is fine. Reflections go in the entry, not in a question to the user.

## Tips

- Log **before** your final response — the connection may close before a deferred call completes
- Log specs and decisions when they happen, not at the end — see [What to log, and when](#what-to-log-and-when)
- Use `resource` when the work relates to a specific PR, ticket, or thread
- Use `supersedes_entry_id` when your work replaces or updates a previous knowledge entry
- Don't repeat what's already captured in commit messages — focus on context and reasoning
