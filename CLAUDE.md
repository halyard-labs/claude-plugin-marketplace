# Claude Plugin Marketplace

Plugin marketplace for the ask-expert Claude Code plugin.

## Critical Rule

**Every commit MUST bump the plugin version.** Use the `plugin-version-bump` skill on every commit. The plugin cache keys on version — stale versions mean users get outdated plugins.

## Structure

```
plugins/
└── ask-expert/
    ├── .claude-plugin/plugin.json   # Version lives here
    ├── .mcp.json                    # MCP server config
    ├── hooks/hooks.json             # Session hooks
    ├── scripts/                     # Hook scripts
    └── skills/                      # Plugin skills
```
