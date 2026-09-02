---
name: review-work
description: >-
  Query the team knowledge base for recent activity, past decisions, and work
  context. Use when the user asks what was done, what happened, what changed,
  wants a standup summary, daily update, weekly review, needs to catch up, get
  up to speed, understand previous work, or asks about past decisions. Triggers
  on 'show me recent work', 'what did the team do', 'review activity', 'what's
  been going on', 'standup', 'what was accomplished'. Searches work summaries,
  expert Q&A, and decision records.
---

# Review Work

Use the halyard MCP tools to query what has been done — by you, your team, or across the organization. This is useful for standups, catching up after time away, understanding context before starting new work, or reviewing what happened in a previous session.

## Quick Start

**Search when you have a topic. List when you don't.**

```
// Looking for something specific? Search first.
mcp__plugin_halyard_org-kb__search_knowledge(query: "authentication refactor")

// General catch-up without a topic? List with filters.
mcp__plugin_halyard_org-kb__list_knowledge(author: "me", since: "this week")

// Need to see how an entry connects to others? Explore its graph.
mcp__plugin_halyard_org-kb__explore_knowledge(entry_id: "entry-id")
```

## Available Tools

### 1. Search Knowledge

Semantic search across all knowledge entries — work summaries, expert Q&A, decisions, and process docs. Use this when you're looking for something specific or want to find relevant context.

```
mcp__plugin_halyard_org-kb__search_knowledge(query: "your search query")
```

**Parameters:**

| Parameter | Description                                                                            |
| --------- | -------------------------------------------------------------------------------------- |
| `query`   | What to search for — uses semantic similarity (required)                               |
| `type`    | Filter by type: `"WORK_OUTPUT"`, `"DECISION"`, `"PROCESS"`, `"CONTEXT"`                |
| `author`  | Filter by author — use `"me"` for your own entries                                     |
| `since`   | Time filter: `"today"`, `"yesterday"`, `"this week"`, `"7d"`, `"30d"`, or an ISO date |
| `limit`   | Max results to return                                                                  |

**Examples:**

```
// What decisions were made about the database?
mcp__plugin_halyard_org-kb__search_knowledge(query: "database", type: "DECISION")

// What did I work on this week?
mcp__plugin_halyard_org-kb__search_knowledge(query: "work completed", author: "me", since: "this week")

// Find past answers about deployment
mcp__plugin_halyard_org-kb__search_knowledge(query: "deployment process")
```

### 2. List Knowledge

Chronological listing of knowledge entries. Use this when you want to see recent activity without a specific search query — great for standups and catch-ups.

```
mcp__plugin_halyard_org-kb__list_knowledge()
```

**Parameters:**

| Parameter | Description                                                                            |
| --------- | -------------------------------------------------------------------------------------- |
| `type`            | Filter by type: `"WORK_OUTPUT"`, `"DECISION"`, `"PROCESS"`, `"CONTEXT"`                |
| `author`          | Filter by author — use `"me"` for your own entries                                     |
| `since`           | Time filter: `"today"`, `"yesterday"`, `"this week"`, `"7d"`, `"30d"`, or an ISO date |
| `limit`           | Max results to return (default: 10)                                                    |
| `include_content` | Include full content in results (default: false)                                       |

**Examples:**

```
// Everything from today
mcp__plugin_halyard_org-kb__list_knowledge(since: "today")

// My work output this week
mcp__plugin_halyard_org-kb__list_knowledge(author: "me", type: "WORK_OUTPUT", since: "this week")

// Recent decisions
mcp__plugin_halyard_org-kb__list_knowledge(type: "DECISION", limit: 5)

// What happened yesterday?
mcp__plugin_halyard_org-kb__list_knowledge(since: "yesterday")
```

### 3. Explore Knowledge Graph

Explore relationships between knowledge entries — see what supersedes what, evidence chains, and connected entries:

```
mcp__plugin_halyard_org-kb__explore_knowledge(
  entry_id: "entry-id"
)
```

**Parameters:**

| Parameter         | Description                                                             |
| ----------------- | ----------------------------------------------------------------------- |
| `entry_id`        | The knowledge entry ID to explore (required)                            |
| `depth`           | How many hops to traverse: `1` or `2` (default: 1)                     |
| `format`          | Output format: `"list"` (default) or `"graph"` (for visualization)     |
| `include_content` | Include full content for related entries (default: false)               |
| `types`           | Filter by relation types (e.g., `["DERIVED_FROM", "SUPERSEDES"]`)      |

Use this after `search_knowledge` to understand how an entry connects to related decisions, work, and processes.

### 4. View User Profile

See a user's expertise areas and recent activity:

```
mcp__plugin_halyard_org-kb__get_user_profile()
mcp__plugin_halyard_org-kb__get_user_profile(since: "this week")
mcp__plugin_halyard_org-kb__get_user_profile(user_id: "user-id")
```

Without `since`, shows accumulated expertise and stats. With `since`, shows time-scoped activity including conversations, knowledge entries, and sessions.

### 5. Update User Profile

Update your living profile document with expertise, preferences, or notes:

```
mcp__plugin_halyard_org-kb__update_user_profile(
  content: "## Expertise\n- TypeScript/React\n- System design\n\n## Preferences\n- Prefer functional patterns over OOP",
  sections: ["Expertise", "Preferences"]
)
```

**Parameters:**

| Parameter  | Description                                                       |
| ---------- | ----------------------------------------------------------------- |
| `content`  | Full markdown content for the profile (required)                  |
| `sections` | Section names you authored — protected from system rewrites       |

### 6. Log Work (When Needed)

If during your review you realize work from the current session should be recorded, use `mcp__plugin_halyard_org-kb__summarize_work`:

```
mcp__plugin_halyard_org-kb__summarize_work(
  title: "Brief description of what was done",
  summary: "Detailed explanation of the work, context, and decisions made",
  tags: ["relevant", "tags"]
)
```

**Parameters:**

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

### 7. Delivery Analytics

Beyond the knowledge base, the org's PR delivery data is queryable — useful for standups, weekly reviews, and "how are we doing this month?".

**Pre-aggregated dashboard** (admin-only) — totals (opened / merged / closed-unmerged), cycle time p50/p90, auto-approval %, per-author and per-repo breakdowns, and an 8-week trend:

```
mcp__plugin_halyard_org-kb__get_delivery_metrics()                 // current month
mcp__plugin_halyard_org-kb__get_delivery_metrics(month: "2026-06") // specific month (YYYY-MM)
```

**Raw events** — for open-ended questions the dashboard doesn't answer ("which PRs sat unreviewed for >5 days?", "what did Alex ship last week?", "compare backend vs frontend cadence"):

```
mcp__plugin_halyard_org-kb__list_events(author: "me", since: "this week")
mcp__plugin_halyard_org-kb__list_events(eventType: ["pull_request_merged"], repo: "halyard-labs/signal", since: "30d")
```

**`list_events` parameters:**

| Parameter          | Description                                                              |
| ------------------ | ------------------------------------------------------------------------ |
| `author`           | Filter by actor — `"me"` or a user ID                                    |
| `eventType`        | e.g. `["pull_request_merged"]`, `["pull_request_review_approved"]`       |
| `repo`             | Single repo, e.g. `"halyard-labs/signal"`                                |
| `since` / `until`  | Time bounds: `"today"`, `"this week"`, `"7d"`, `"30d"`, `"90d"`, or ISO  |
| `limit` / `offset` | Pagination (default limit 20)                                            |

Prefer `get_delivery_metrics` for dashboard-shaped numbers — its server-side aggregation is more reliable than reconstructing cycle time client-side. Use `list_events` for ad-hoc slicing.

### 8. Retire Stale Entries

When a review surfaces an entry that's outdated, wrong, or duplicated, retire it:

```
mcp__plugin_halyard_org-kb__delete_knowledge(knowledge_entry_id: "ke_...")             // archives — reversible
mcp__plugin_halyard_org-kb__delete_knowledge(knowledge_entry_id: "ke_...", hard: true) // permanent — spam/secrets only
```

Archiving hides the entry from search and the wiki but keeps it recoverable — prefer it over hard deletes. When you're *replacing* knowledge rather than removing it, prefer `supersedes_entry_id` on the new entry (see the **log-work** skill) so the chain is preserved.

> **Reviewing the inbox queue:** agent-authored entries wait in a review queue before going live. To accept, dismiss, or edit those candidates, use the **triage-knowledge** skill (`list_triage`, `accept_triage`, `dismiss_triage`, …).

## Knowledge Types

Entries in the knowledge base fall into these categories:

| Type          | What it contains                                        | Created by                |
| ------------- | ------------------------------------------------------- | ------------------------- |
| `WORK_OUTPUT` | Code and implementation work summaries                  | `summarize_work`          |
| `DECISION`    | Architectural and design decisions with reasoning       | `summarize_work`          |
| `PROCESS`     | Repeatable procedures a reader can follow again — how-tos, runbooks, conventions (not a record of steps performed once) | `summarize_work`          |
| `CONTEXT`     | Background context, research, or reference material     | `summarize_work`          |

**Note:** Expert Q&A entries are created automatically by `summarize_conversation` and appear in search results, but are not a `type` filter value you pass to `search_knowledge` or `list_knowledge`.

## Common Scenarios

### Morning standup / catch-up
```
mcp__plugin_halyard_org-kb__list_knowledge(author: "me", since: "yesterday")
```

### Starting a new task — find relevant context
```
mcp__plugin_halyard_org-kb__search_knowledge(query: "describe the feature or area you're about to work on")
```

### Weekly review
```
mcp__plugin_halyard_org-kb__list_knowledge(since: "this week")
```

### Find out what a teammate worked on
```
mcp__plugin_halyard_org-kb__search_knowledge(query: "what was done", since: "this week")
```

### Check if a question was already answered
```
mcp__plugin_halyard_org-kb__search_knowledge(query: "your question")
```

## Reviewing Reflections

When reviewing past work, look for reflection bullets in work summaries. These capture what worked, what didn't, learnings, and suggestions from previous sessions.

Use reflections to:

- **Spot patterns** — If multiple sessions mention the same dead end or workaround, that's a signal worth surfacing
- **Inform current work** — Before starting a task, check if past reflections flagged relevant gotchas or effective approaches
- **Surface suggestions** — Past sessions may have recommended improvements that haven't been acted on yet

```
// Find sessions with reflections about a specific area
mcp__plugin_halyard_org-kb__search_knowledge(query: "reflections on deployment", type: "WORK_OUTPUT")

// Review recent reflections across the team
mcp__plugin_halyard_org-kb__list_knowledge(type: "WORK_OUTPUT", since: "this week", include_content: true)
```

When presenting a review to the user, call out any notable reflections — especially recurring themes or unactioned suggestions. Share one that feels relevant and ask if the user has thoughts:

> *One pattern I noticed across recent sessions: [reflection]. Worth addressing?*

## Tips

- **Search when you have a topic, list when you don't** — If the ask is specific ("what do we know about auth?"), use `mcp__plugin_halyard_org-kb__search_knowledge`. If it's a general catch-up ("what happened this week?"), use `mcp__plugin_halyard_org-kb__list_knowledge` with time/author filters.
- **Use time filters** — `since` is your best friend for scoping results to relevant timeframes
- **Use `"me"` for your own work** — The `author: "me"` filter resolves to your user automatically
- **Search before asking experts** — Someone may have already asked the same question
- **Combine filters** — Use `type` + `since` + `author` together to get exactly what you need
