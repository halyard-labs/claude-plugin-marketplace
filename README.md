# Ask Expert — Claude Code Plugin Marketplace

A plugin marketplace that connects Claude Code to human experts via Slack.

## What's included

### `ask-expert` plugin

Installs two things into Claude Code:

1. **`ask-expert` MCP server** — Connects to the Ask Expert API at `mcp.ask-expert.ai`, giving Claude access to tools for messaging experts on Slack, polling for responses, and managing a knowledge base.

2. **`ask-for-help` skill** — Teaches Claude *when* and *how* to ask for human input. Claude will automatically consult experts when it hits ambiguous requirements, design decisions, or anything that needs human judgment. It also learns to summarize answers so the same question doesn't get asked twice.

## Quick start

### From a local clone

```bash
# Add the marketplace
/plugin marketplace add ./path/to/claude-plugin-marketplace

# Install the plugin
/plugin install ask-expert@ask-expert-marketplace
```

### From GitHub

```bash
# Add the marketplace
/plugin marketplace add halyard-labs/claude-plugin-marketplace

# Install the plugin
/plugin install ask-expert@ask-expert-marketplace
```

## Prerequisites

- An account at [ask-expert.ai](https://ask-expert.ai) with your Slack workspace connected
- Claude Code v1.0.33 or later

## After installation

Once installed, Claude will automatically:

- Use the `ask-expert` MCP tools when it needs human input
- Follow the ask → wait → summarize workflow
- Search the knowledge base before asking repeat questions
- Save learnings so your team's knowledge compounds over time

You can also invoke the skill manually:

```
/ask-expert:ask-for-help
```

## Team setup

To have this plugin auto-suggested when teammates open a project, add this to your repo's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "ask-expert-marketplace": {
      "source": {
        "source": "github",
        "repo": "halyard-labs/claude-plugin-marketplace"
      }
    }
  },
  "enabledPlugins": {
    "ask-expert@ask-expert-marketplace": true
  }
}
```

## Project structure

```
claude-plugin-marketplace/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace catalog
├── plugins/
│   └── ask-expert/
│       ├── .claude-plugin/
│       │   └── plugin.json       # Plugin manifest
│       ├── skills/
│       │   └── ask-for-help/
│       │       └── SKILL.md      # Skill definition
│       └── .mcp.json             # MCP server config
├── LICENSE
└── README.md
```
