# Claude Plugin Marketplace

Plugin marketplace for the halyard plugin (Claude Code, Codex, and Cursor).

## Critical Rules

**Every commit MUST bump the plugin version.** Use the `plugin-version-bump` skill on every commit. The plugin cache keys on version — stale versions mean users get outdated plugins.

**Keep all version fields in sync.** When bumping a plugin's version, update all 6 locations:
- `plugins/halyard/.claude-plugin/plugin.json` (Claude Code manifest)
- `plugins/halyard/.codex-plugin/plugin.json` (Codex manifest)
- `plugins/halyard/.cursor-plugin/plugin.json` (Cursor manifest)
- `.claude-plugin/marketplace.json` — the plugin entry's `version` field
- `.claude-plugin/marketplace.json` — the catalog-level `metadata.version` field
- `.cursor-plugin/marketplace.json` — the catalog-level `metadata.version` field

Mismatched versions break auto-update — Claude Code won't detect new versions if the marketplace plugin entry is stale. The Codex marketplace (`.agents/plugins/marketplace.json`) intentionally has no plugin version field; don't add one. The Cursor marketplace plugin entries also have no per-plugin version field (matching `cursor/plugin-template`); don't add one there either.

**Always bump `metadata.version` alongside the per-plugin versions.** The catalog-level version is bumped on every update — do not skip it.

**Keep the two MCP config files in sync.** `plugins/halyard/.mcp.json` (Claude Code + Codex, `type`/`url` format) and `plugins/halyard/mcp.json` (Cursor, `url`-only format) point at the same server. If the server URL changes, change both.

**Cursor releases are re-reviewed.** The Cursor Marketplace manually re-reviews plugin updates before they go live — a version bump here does not instantly ship to Cursor users. See `docs/cursor-marketplace-submission.md`.

## Structure

```
.agents/
└── plugins/
    └── marketplace.json             # Codex marketplace catalog
.claude-plugin/
└── marketplace.json                 # Claude Code marketplace catalog
.cursor-plugin/
└── marketplace.json                 # Cursor marketplace catalog
docs/
└── cursor-marketplace-submission.md # Cursor submission copy + checklist
plugins/
└── halyard/
    ├── .claude-plugin/plugin.json   # Claude Code plugin manifest
    ├── .codex-plugin/plugin.json    # Codex plugin manifest
    ├── .cursor-plugin/plugin.json   # Cursor plugin manifest
    ├── .mcp.json                    # MCP server config (Claude Code + Codex)
    ├── mcp.json                     # MCP server config (Cursor — no leading dot)
    ├── README.md                    # Plugin README (Cursor listing body)
    ├── assets/                      # Brand assets (logos)
    ├── hooks/hooks.json             # Session hooks (Claude Code only)
    ├── rules/                       # Always-on rules (Cursor only)
    └── skills/                      # Plugin skills (shared)
```
