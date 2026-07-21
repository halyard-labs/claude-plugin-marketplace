---
name: log-work
description: >-
  Log completed work to the team knowledge base. Use when finishing a session,
  completing a task, wrapping up, making a decision, or when prompted to record,
  document, save, or summarize what was done. Triggers on 'log this', 'write this
  up', 'save to knowledge base', 'document what we did', 'record this decision',
  'summarize this session'. Captures work summaries, architectural decisions,
  process documentation, and learnings for team visibility.
---

# Log Work

After completing all work in this session, call `mcp__plugin_halyard_org-kb__summarize_work` to log what was accomplished.

Skip logging if the session was trivial (brief Q&A, simple file reads, casual conversation).

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
| `tags`                     | Tags for categorization                                                                |
| `knowledge_entry_id`       | ID of an existing entry to update instead of creating new                              |
| `source_provider`          | Source system: `"github"`, `"slack"`, `"linear"`, `"claude"`, `"codex"`, `"notion"`    |
| `resource`                 | Navigable link to the source material (PR, ticket, thread)                             |
| `source_knowledge_entry_id`| ID of another entry this derives from (citation chain)                                 |
| `supersedes_entry_id`      | ID of an older entry this replaces (marks it outdated)                                 |
| `session_id`               | Link this entry to a specific agent session                                            |

## Choosing an entry type

- **`WORK_OUTPUT`** — Code changes, feature implementations, bug fixes, refactors
- **`DECISION`** — Architectural choices, design trade-offs, technology selections (include reasoning)
- **`PROCESS`** — How-to documentation, workflow descriptions, setup procedures
- **`CONTEXT`** — Background research, reference material, exploratory findings
- **`SPEC`** — Plans, specifications, project descriptions

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

Be genuine, not performative. Skip a category if nothing meaningful to say. Be specific — "Grep was faster than Agent for finding the config" beats "tools worked well." If the session was straightforward, a single bullet is fine.

After logging, share one of your reflections with the user as a conversation starter and ask for theirs:

> *One thing I noticed: [your reflection]. Any thoughts from your side on this session?*

## Tips

- Log **before** your final response — the connection may close before a deferred call completes
- Use `resource` when the work relates to a specific PR, ticket, or thread
- Use `supersedes_entry_id` when your work replaces or updates a previous knowledge entry
- Don't repeat what's already captured in commit messages — focus on context and reasoning
