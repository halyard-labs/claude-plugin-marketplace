---
name: review-work
description: >-
  Review what you or your team have been working on by querying the knowledge
  base. Search work summaries, decisions, and Q&A from past sessions to
  understand recent activity and find context. Use when the user asks what
  was done, what happened, what changed, wants a standup summary, needs
  context on previous work, or asks about past decisions.
---

# Review Work

Use the halyard MCP tools to query what has been done — by you, your team, or across the organization. This is useful for standups, catching up after time away, understanding context before starting new work, or reviewing what happened in a previous session.

## Quick Start

The most common workflow is a simple search or list:

```
// What has been done recently?
mcp__plugin_halyard_ask-expert__list_knowledge(since: "this week")

// What did I work on today?
mcp__plugin_halyard_ask-expert__list_knowledge(author: "me", since: "today")

// Search for something specific
mcp__plugin_halyard_ask-expert__search_knowledge(query: "authentication refactor")
```

## Available Tools

### 1. Search Knowledge

Semantic search across all knowledge entries — work summaries, expert Q&A, decisions, and process docs. Use this when you're looking for something specific or want to find relevant context.

```
mcp__plugin_halyard_ask-expert__search_knowledge(query: "your search query")
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
mcp__plugin_halyard_ask-expert__search_knowledge(query: "database", type: "DECISION")

// What did I work on this week?
mcp__plugin_halyard_ask-expert__search_knowledge(query: "work completed", author: "me", since: "this week")

// Find past answers about deployment
mcp__plugin_halyard_ask-expert__search_knowledge(query: "deployment process")
```

### 2. List Knowledge

Chronological listing of knowledge entries. Use this when you want to see recent activity without a specific search query — great for standups and catch-ups.

```
mcp__plugin_halyard_ask-expert__list_knowledge()
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
mcp__plugin_halyard_ask-expert__list_knowledge(since: "today")

// My work output this week
mcp__plugin_halyard_ask-expert__list_knowledge(author: "me", type: "WORK_OUTPUT", since: "this week")

// Recent decisions
mcp__plugin_halyard_ask-expert__list_knowledge(type: "DECISION", limit: 5)

// What happened yesterday?
mcp__plugin_halyard_ask-expert__list_knowledge(since: "yesterday")
```

### 3. Explore Knowledge Graph

Explore relationships between knowledge entries — see what supersedes what, evidence chains, and connected entries:

```
mcp__plugin_halyard_ask-expert__explore_knowledge(
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
mcp__plugin_halyard_ask-expert__get_user_profile()
mcp__plugin_halyard_ask-expert__get_user_profile(since: "this week")
mcp__plugin_halyard_ask-expert__get_user_profile(user_id: "user-id")
```

Without `since`, shows accumulated expertise and stats. With `since`, shows time-scoped activity including conversations, knowledge entries, and sessions.

### 5. Update User Profile

Update your living profile document with expertise, preferences, or notes:

```
mcp__plugin_halyard_ask-expert__update_user_profile(
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

If during your review you realize work from the current session should be recorded, use `mcp__plugin_halyard_ask-expert__summarize_work`:

```
mcp__plugin_halyard_ask-expert__summarize_work(
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
| `entry_type`               | Type: `"WORK_OUTPUT"` (default), `"DECISION"`, `"PROCESS"`, or `"CONTEXT"`             |
| `tags`                     | Tags for categorization                                                                |
| `knowledge_entry_id`       | ID of an existing entry to update instead of creating new                              |
| `source_provider`          | Source system: `"github"`, `"slack"`, `"linear"`, `"claude"`, `"codex"`, `"notion"`    |
| `source_url`               | Navigable link to the source material (PR, ticket, thread)                             |
| `source_knowledge_entry_id`| ID of another entry this derives from (citation chain)                                 |
| `supersedes_entry_id`      | ID of an older entry this replaces (marks it outdated)                                 |
| `session_id`               | Link this entry to a specific agent session                                            |

## Knowledge Types

Entries in the knowledge base fall into these categories:

| Type          | What it contains                                        | Created by                |
| ------------- | ------------------------------------------------------- | ------------------------- |
| `WORK_OUTPUT` | Code and implementation work summaries                  | `summarize_work`          |
| `DECISION`    | Architectural and design decisions with reasoning       | `summarize_work`          |
| `PROCESS`     | How-to documentation and process notes                  | `summarize_work`          |
| `CONTEXT`     | Background context, research, or reference material     | `summarize_work`          |

**Note:** Expert Q&A entries are created automatically by `summarize_conversation` and appear in search results, but are not a `type` filter value you pass to `search_knowledge` or `list_knowledge`.

## Common Scenarios

### Morning standup / catch-up
```
mcp__plugin_halyard_ask-expert__list_knowledge(author: "me", since: "yesterday")
```

### Starting a new task — find relevant context
```
mcp__plugin_halyard_ask-expert__search_knowledge(query: "describe the feature or area you're about to work on")
```

### Weekly review
```
mcp__plugin_halyard_ask-expert__list_knowledge(since: "this week")
```

### Find out what a teammate worked on
```
mcp__plugin_halyard_ask-expert__search_knowledge(query: "what was done", since: "this week")
```

### Check if a question was already answered
```
mcp__plugin_halyard_ask-expert__search_knowledge(query: "your question")
```

## Reviewing Reflections

When reviewing past work, look for reflection bullets in work summaries. These capture what worked, what didn't, learnings, and suggestions from previous sessions.

Use reflections to:

- **Spot patterns** — If multiple sessions mention the same dead end or workaround, that's a signal worth surfacing
- **Inform current work** — Before starting a task, check if past reflections flagged relevant gotchas or effective approaches
- **Surface suggestions** — Past sessions may have recommended improvements that haven't been acted on yet

```
// Find sessions with reflections about a specific area
mcp__plugin_halyard_ask-expert__search_knowledge(query: "reflections on deployment", type: "WORK_OUTPUT")

// Review recent reflections across the team
mcp__plugin_halyard_ask-expert__list_knowledge(type: "WORK_OUTPUT", since: "this week", include_content: true)
```

When presenting a review to the user, call out any notable reflections — especially recurring themes or unactioned suggestions. Share one that feels relevant and ask if the user has thoughts:

> *One pattern I noticed across recent sessions: [reflection]. Worth addressing?*

## Tips

- **Start broad, then narrow** — Try `mcp__plugin_halyard_ask-expert__list_knowledge` first to see what's there, then use `mcp__plugin_halyard_ask-expert__search_knowledge` for specifics
- **Use time filters** — `since` is your best friend for scoping results to relevant timeframes
- **Use `"me"` for your own work** — The `author: "me"` filter resolves to your user automatically
- **Search before asking experts** — Someone may have already asked the same question
- **Combine filters** — Use `type` + `since` + `author` together to get exactly what you need
