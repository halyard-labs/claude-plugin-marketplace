# Halyard — Claude Code Plugin Marketplace

A plugin marketplace that connects Claude Code to human experts via Slack.

## What's included

### `halyard` plugin

Installs the following into Claude Code:

1. **`ask-expert` MCP server** — Connects to the Halyard API at `mcp.usehalyard.ai`, giving Claude access to tools for messaging experts on Slack, polling for responses, and managing a knowledge base.

2. **`ask-for-help` skill** — Teaches Claude *when* and *how* to ask for human input. Claude will automatically consult experts when it hits ambiguous requirements, design decisions, or anything that needs human judgment. It also learns to summarize answers so the same question doesn't get asked twice.

3. **`log-work` skill** — Prompts Claude to log non-trivial work using the knowledge base so accomplishments are captured for future reference.

4. **`review-work` skill** — Lets Claude query the knowledge base to review what you or your team have been working on — useful for standups, catch-ups, and finding past context.

5. **Stop hook** — Automatically evaluates whether meaningful work was done at the end of a session and prompts Claude to log it if it hasn't been captured yet.

## Quick start

### From a local clone

```bash
# Add the marketplace
/plugin marketplace add ./path/to/claude-plugin-marketplace

# Install the plugin
/plugin install halyard@halyard-labs
```

### From GitHub

```bash
# Add the marketplace
/plugin marketplace add halyard-labs/claude-plugin-marketplace

# Install the plugin
/plugin install halyard@halyard-labs
```

### Enable for your entire team (recommended)

Instead of having each teammate install manually, add the marketplace and plugin to your repo's `.claude/settings.json`. This enables the plugin automatically for anyone who opens the project in Claude Code:

```json
{
  "enabledPlugins": {
    "halyard@halyard-labs": true
  },
  "extraKnownMarketplaces": {
    "halyard-labs": {
      "source": {
        "source": "github",
        "repo": "halyard-labs/claude-plugin-marketplace"
      }
    }
  }
}
```

Commit this file to your repo — teammates will get the plugin enabled on their next session without any manual setup.

## Codex CLI support

The halyard plugin is also available as a Codex plugin. The skills and MCP server are shared between Claude Code and Codex.

### From a local clone

```bash
# Add the Codex marketplace
codex plugin marketplace add ./path/to/claude-plugin-marketplace

# Install the plugin
codex plugin install halyard@halyard-labs
```

### From GitHub

```bash
# Add the Codex marketplace
codex plugin marketplace add halyard-labs/claude-plugin-marketplace

# Install the plugin
codex plugin install halyard@halyard-labs
```

### Manual MCP setup (alternative)

If you prefer manual configuration instead of the plugin system:

```bash
codex mcp add ask-expert --url https://mcp.usehalyard.ai
codex mcp login ask-expert
```

## Prerequisites

- An account at [usehalyard.ai](https://usehalyard.ai) with your Slack workspace connected
- Claude Code v1.0.33 or later (for Claude Code), or [Codex CLI](https://github.com/openai/codex) (for Codex)

## After installation

Once installed, Claude will automatically:

- Use the halyard MCP tools when it needs human input
- Follow the ask → wait → summarize workflow
- Search the knowledge base before asking repeat questions
- Save learnings so your team's knowledge compounds over time
- Prompt to log meaningful work at the end of each session

You can also invoke skills manually:

```
/halyard:ask-for-help     # Ask a human expert for help
/halyard:log-work         # Log work to the knowledge base
/halyard:review-work      # Review past work and decisions
```

## Team setup

To have this plugin auto-suggested when teammates open a project, add this to your repo's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "halyard-labs": {
      "source": {
        "source": "github",
        "repo": "halyard-labs/claude-plugin-marketplace"
      }
    }
  },
  "enabledPlugins": {
    "halyard@halyard-labs": true
  }
}
```

## Project structure

```
claude-plugin-marketplace/
├── .agents/
│   └── plugins/
│       └── marketplace.json      # Codex marketplace catalog
├── .claude-plugin/
│   └── marketplace.json          # Claude Code marketplace catalog
├── plugins/
│   └── halyard/
│       ├── .claude-plugin/
│       │   └── plugin.json       # Claude Code plugin manifest
│       ├── .codex-plugin/
│       │   └── plugin.json       # Codex plugin manifest
│       ├── assets/               # Brand assets (logos)
│       ├── hooks/
│       │   └── hooks.json        # Session hooks (Claude Code only)
│       ├── skills/
│       │   ├── ask-for-help/
│       │   │   └── SKILL.md      # Ask experts for help
│       │   ├── log-work/
│       │   │   └── SKILL.md      # Log work to knowledge base
│       │   └── review-work/
│       │       └── SKILL.md      # Review past work and decisions
│       └── .mcp.json             # MCP server config (shared)
├── LICENSE
└── README.md
```
