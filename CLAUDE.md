# Claude Plugin Marketplace

Plugin marketplace for the ask-expert Claude Code plugin.

## Critical Rules

**Every commit MUST bump the plugin version.** Use the `plugin-version-bump` skill on every commit. The plugin cache keys on version — stale versions mean users get outdated plugins.

**Keep marketplace.json in sync.** When bumping a plugin's version in `plugin.json`, also update the matching entry's `version` in `.claude-plugin/marketplace.json`. Mismatched versions break auto-update — Claude Code won't detect new versions if marketplace.json is stale.

## Structure

```
.claude-plugin/
└── marketplace.json                 # Marketplace catalog — plugin versions here must match plugin.json
plugins/
└── ask-expert/
    ├── .claude-plugin/plugin.json   # Plugin manifest — authoritative version lives here
    ├── .mcp.json                    # MCP server config
    ├── hooks/hooks.json             # Session hooks
    ├── scripts/                     # Hook scripts
    └── skills/                      # Plugin skills
```
