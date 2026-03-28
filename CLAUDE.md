# Claude Plugin Marketplace

Plugin marketplace for the halyard Claude Code plugin.

## Critical Rules

**Every commit MUST bump the plugin version.** Use the `plugin-version-bump` skill on every commit. The plugin cache keys on version — stale versions mean users get outdated plugins.

**Keep all version fields in sync.** When bumping a plugin's version, update all 4 locations:
- `plugins/halyard/.claude-plugin/plugin.json` (Claude Code manifest)
- `plugins/halyard/.codex-plugin/plugin.json` (Codex manifest)
- `.claude-plugin/marketplace.json` (Claude Code marketplace)
- `.agents/plugins/marketplace.json` (Codex marketplace)

Mismatched versions break auto-update — clients won't detect new versions if marketplace files are stale.

## Structure

```
.agents/
└── plugins/
    └── marketplace.json             # Codex marketplace catalog
.claude-plugin/
└── marketplace.json                 # Claude Code marketplace catalog
plugins/
└── halyard/
    ├── .claude-plugin/plugin.json   # Claude Code plugin manifest
    ├── .codex-plugin/plugin.json    # Codex plugin manifest
    ├── .mcp.json                    # MCP server config (shared)
    ├── assets/                      # Brand assets (logos)
    ├── hooks/hooks.json             # Session hooks (Claude Code only)
    └── skills/                      # Plugin skills (shared)
```
