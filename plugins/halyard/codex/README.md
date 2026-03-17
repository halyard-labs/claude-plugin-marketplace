# Halyard for Codex CLI

Connect Codex CLI to human experts via Slack using the Halyard MCP server.

## Prerequisites

- An account at [usehalyard.ai](https://usehalyard.ai) with your Slack workspace connected
- [Codex CLI](https://github.com/openai/codex) installed

## Setup

### 1. Add the MCP server

**Option A — CLI command:**

```bash
codex mcp add ask-expert --url https://mcp.usehalyard.ai
```

**Option B — Manual config:**

Copy the contents of `config.toml` in this directory to your Codex config:

- **Global:** `~/.codex/config.toml`
- **Project-scoped:** `.codex/config.toml` in your repo root

### 2. Authenticate

```bash
codex mcp login ask-expert
```

### 3. Use the skills

The halyard skills in `plugins/halyard/skills/` follow the [Agent Skills standard](https://agentskills.io) and work directly with Codex CLI. The skills teach your agent when and how to:

- **Ask for help** (`ask-for-help`) — Query human experts via Slack when blocked or facing ambiguity
- **Log work** (`log-work`) — Capture meaningful work to the knowledge base
- **Review work** (`review-work`) — Query past work, decisions, and expert Q&A

## What's available

| Feature | Status |
|---------|--------|
| MCP tools (ask experts, search knowledge, log work) | Fully supported |
| Skills (behavioral instructions) | Supported via Agent Skills standard |
| Stop hook (auto-prompt work logging) | Not available — log work manually |
| Plugin auto-install | Not available — manual setup required |

## MCP tools reference

Once the MCP server is configured, Codex has access to these tools:

- `list_experts` — Find available experts by role, skill, or semantic search
- `ask_expert` — Send a question to an expert via Slack
- `check_response` — Wait for the expert's reply
- `reply_to_expert` — Send follow-up messages
- `summarize_conversation` — Capture Q&A as organizational knowledge
- `search_knowledge` — Semantic search across the knowledge base
- `list_knowledge` — Chronological listing of knowledge entries
- `explore_knowledge` — Traverse the knowledge graph
- `summarize_work` — Log work to the knowledge base
- `get_user_profile` — View expertise and activity
- `update_user_profile` — Update your profile document

For detailed usage, see the skill files in `plugins/halyard/skills/`.
