---
name: log-work
description: Log non-trivial work using the summarize_work tool once all work has been completed.
---

# Log Work

After completing all work in this session, call `mcp__plugin_halyard_ask-expert__summarize_work` to log what was accomplished.

Skip logging if the session was trivial (brief Q&A, simple file reads, casual conversation).

## Usage

```
mcp__plugin_halyard_ask-expert__summarize_work(
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
| `entry_type`               | Type: `"WORK_OUTPUT"` (default), `"DECISION"`, `"PROCESS"`, or `"CONTEXT"`             |
| `tags`                     | Tags for categorization                                                                |
| `knowledge_entry_id`       | ID of an existing entry to update instead of creating new                              |
| `source_provider`          | Source system: `"github"`, `"slack"`, `"linear"`, `"claude"`, `"codex"`, `"notion"`    |
| `source_url`               | Navigable link to the source material (PR, ticket, thread)                             |
| `source_knowledge_entry_id`| ID of another entry this derives from (citation chain)                                 |
| `supersedes_entry_id`      | ID of an older entry this replaces (marks it outdated)                                 |
| `session_id`               | Link this entry to a specific agent session                                            |

## Choosing an entry type

- **`WORK_OUTPUT`** — Code changes, feature implementations, bug fixes, refactors
- **`DECISION`** — Architectural choices, design trade-offs, technology selections (include reasoning)
- **`PROCESS`** — How-to documentation, workflow descriptions, setup procedures
- **`CONTEXT`** — Background research, reference material, exploratory findings

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
- Use `source_url` when the work relates to a specific PR, ticket, or thread
- Use `supersedes_entry_id` when your work replaces or updates a previous knowledge entry
- Don't repeat what's already captured in commit messages — focus on context and reasoning
