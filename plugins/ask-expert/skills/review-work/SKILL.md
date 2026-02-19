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

Use the ask-expert MCP tools to query what has been done — by you, your team, or across the organization. This is useful for standups, catching up after time away, understanding context before starting new work, or reviewing what happened in a previous session.

## Quick Start

The most common workflow is a simple search or list:

```
// What has been done recently?
mcp__ask-expert__list_knowledge(since: "this week")

// What did I work on today?
mcp__ask-expert__list_knowledge(author: "me", since: "today")

// Search for something specific
mcp__ask-expert__search_knowledge(query: "authentication refactor")
```

## Available Tools

### 1. Search Knowledge

Semantic search across all knowledge entries — work summaries, expert Q&A, decisions, and process docs. Use this when you're looking for something specific or want to find relevant context.

```
mcp__ask-expert__search_knowledge(query: "your search query")
```

**Parameters:**

| Parameter | Description                                                                            |
| --------- | -------------------------------------------------------------------------------------- |
| `query`   | What to search for — uses semantic similarity (required)                               |
| `type`    | Filter by type: `"QA"`, `"WORK_OUTPUT"`, `"DECISION"`, `"PROCESS"`                    |
| `author`  | Filter by author — use `"me"` for your own entries                                     |
| `since`   | Time filter: `"today"`, `"yesterday"`, `"this week"`, `"7d"`, `"30d"`, or an ISO date |
| `limit`   | Max results to return                                                                  |

**Examples:**

```
// What decisions were made about the database?
mcp__ask-expert__search_knowledge(query: "database", type: "DECISION")

// What did I work on this week?
mcp__ask-expert__search_knowledge(query: "work completed", author: "me", since: "this week")

// Find past answers about deployment
mcp__ask-expert__search_knowledge(query: "deployment process", type: "QA")
```

### 2. List Knowledge

Chronological listing of knowledge entries. Use this when you want to see recent activity without a specific search query — great for standups and catch-ups.

```
mcp__ask-expert__list_knowledge()
```

**Parameters:**

| Parameter | Description                                                                            |
| --------- | -------------------------------------------------------------------------------------- |
| `type`    | Filter by type: `"QA"`, `"WORK_OUTPUT"`, `"DECISION"`, `"PROCESS"`                    |
| `author`  | Filter by author — use `"me"` for your own entries                                     |
| `since`   | Time filter: `"today"`, `"yesterday"`, `"this week"`, `"7d"`, `"30d"`, or an ISO date |
| `limit`   | Max results to return (default: 10)                                                    |

**Examples:**

```
// Everything from today
mcp__ask-expert__list_knowledge(since: "today")

// My work output this week
mcp__ask-expert__list_knowledge(author: "me", type: "WORK_OUTPUT", since: "this week")

// Recent decisions
mcp__ask-expert__list_knowledge(type: "DECISION", limit: 5)

// What happened yesterday?
mcp__ask-expert__list_knowledge(since: "yesterday")
```

### 3. Log Work (When Needed)

If during your review you realize work from the current session should be recorded, use `summarize_work`:

```
mcp__ask-expert__summarize_work(
  title: "Brief description of what was done",
  summary: "Detailed explanation of the work, context, and decisions made",
  tags: ["relevant", "tags"]
)
```

**Parameters:**

| Parameter    | Description                                                            |
| ------------ | ---------------------------------------------------------------------- |
| `title`      | Short title for the work entry (required)                              |
| `summary`    | Detailed summary of what was done and why (required)                   |
| `entry_type` | Type: `"WORK_OUTPUT"` (default), `"DECISION"`, or `"PROCESS"`         |
| `tags`       | Tags for categorization                                                |

## Knowledge Types

Entries in the knowledge base fall into these categories:

| Type          | What it contains                                        | Created by                |
| ------------- | ------------------------------------------------------- | ------------------------- |
| `QA`          | Expert Q&A — questions asked and answers received       | `summarize_conversation`  |
| `WORK_OUTPUT` | Code and implementation work summaries                  | `summarize_work`          |
| `DECISION`    | Architectural and design decisions with reasoning       | `summarize_work`          |
| `PROCESS`     | How-to documentation and process notes                  | `summarize_work`          |

## Common Scenarios

### Morning standup / catch-up
```
mcp__ask-expert__list_knowledge(author: "me", since: "yesterday")
```

### Starting a new task — find relevant context
```
mcp__ask-expert__search_knowledge(query: "describe the feature or area you're about to work on")
```

### Weekly review
```
mcp__ask-expert__list_knowledge(since: "this week")
```

### Find out what a teammate worked on
```
mcp__ask-expert__search_knowledge(query: "what was done", since: "this week")
```

### Check if a question was already answered
```
mcp__ask-expert__search_knowledge(query: "your question", type: "QA")
```

## Tips

- **Start broad, then narrow** — Try `list_knowledge` first to see what's there, then use `search_knowledge` for specifics
- **Use time filters** — `since` is your best friend for scoping results to relevant timeframes
- **Use `"me"` for your own work** — The `author: "me"` filter resolves to your user automatically
- **Check QA entries before asking experts** — Someone may have already asked the same question
- **Combine filters** — Use `type` + `since` + `author` together to get exactly what you need
