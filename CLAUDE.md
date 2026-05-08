# Claude Plugin Marketplace

Plugin marketplace for the halyard Claude Code plugin.

## Critical Rules

**Every commit MUST bump the plugin version.** Use the `plugin-version-bump` skill on every commit. The plugin cache keys on version — stale versions mean users get outdated plugins.

**Keep all version fields in sync.** When bumping a plugin's version, update all 4 locations:
- `plugins/halyard/.claude-plugin/plugin.json` (Claude Code manifest)
- `plugins/halyard/.codex-plugin/plugin.json` (Codex manifest)
- `.claude-plugin/marketplace.json` — the plugin entry's `version` field
- `.claude-plugin/marketplace.json` — the catalog-level `metadata.version` field

Mismatched versions break auto-update — Claude Code won't detect new versions if the marketplace plugin entry is stale. The Codex marketplace (`.agents/plugins/marketplace.json`) intentionally has no plugin version field; don't add one.

**Always bump `metadata.version` alongside the per-plugin versions.** The catalog-level version is bumped on every update — do not skip it.

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
