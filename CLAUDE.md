# Claude Plugin Marketplace

Plugin marketplace for the halyard Claude Code plugin.

## Critical Rules

**Every commit MUST bump the plugin version.** Use the `plugin-version-bump` skill on every commit. The plugin cache keys on version — stale versions mean users get outdated plugins.

**Keep all version fields in sync.** When bumping a plugin's version, update all 3 locations:
- `plugins/halyard/.claude-plugin/plugin.json` (Claude Code manifest)
- `plugins/halyard/.codex-plugin/plugin.json` (Codex manifest)
- `.claude-plugin/marketplace.json` — the plugin entry's `version` field (not `metadata.version`)

Mismatched versions break auto-update — Claude Code won't detect new versions if the marketplace plugin entry is stale. The Codex marketplace (`.agents/plugins/marketplace.json`) intentionally has no plugin version field; don't add one.

**Do not add `metadata.version` back to `.claude-plugin/marketplace.json`.** It was removed deliberately — the catalog-level version was never bumped reliably and adding it back creates a sync surface we don't maintain.

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
