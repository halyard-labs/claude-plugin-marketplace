# Cursor Marketplace — Submission Copy & Checklist

Copy and process notes for submitting the halyard plugin to the Cursor
Marketplace at [cursor.com/marketplace/publish](https://cursor.com/marketplace/publish).

Cursor generates the marketplace listing from the plugin manifest
(`plugins/halyard/.cursor-plugin/plugin.json`) and the plugin README
(`plugins/halyard/README.md`) — there is no separate marketing-copy form
documented. The copy below is the canonical source for those fields, plus
spare variants (tagline, short description) in case the submission form asks
for them.

## Listing copy

**Name:** Halyard

**Tagline (~50 chars):** Shared team memory for AI agents.

**Short description (~140 chars):**

> Give Cursor your org's memory: recall past decisions, log work, and ask a
> teammate on Slack when the answer isn't written down.

**Manifest description (shipped in `plugin.json`):**

> Shared team memory for AI agents. Log decisions, recall past work, gather
> context, and ask teammates on Slack, Teams, or Discord when you need a
> human.

**Long description:** the plugin README (`plugins/halyard/README.md`) is the
long-form listing body. Keep it as the single source of truth.

**Category:** Collaboration (fallbacks: Productivity, Knowledge)

**Keywords:** memory, context, knowledge-base, organizational-knowledge,
slack, experts, human-in-the-loop, collaboration, search, history

**Logo:** `plugins/halyard/assets/halyard-mark.svg` (referenced from the
manifest's `logo` field; `assets/halyard-lockup.svg` available if a wide
variant is requested)

**Links:**

- Homepage: https://usehalyard.ai
- Docs: https://usehalyard.ai/docs/connect-agent/cursor/
- Support: support@halyard.studio

## Submission checklist

Cursor's documented requirements ([docs](https://cursor.com/docs/reference/plugins)):

- [x] Manifest at `plugins/halyard/.cursor-plugin/plugin.json` (`name` is the
      only required field; ours also ships displayName, description, version,
      author, license, keywords, logo)
- [x] Catalog at `.cursor-plugin/marketplace.json` (multi-plugin repo layout,
      same as `cursor/plugin-template`)
- [x] MCP config at `plugins/halyard/mcp.json` — note: **no leading dot**
      (Claude Code's `.mcp.json` is a separate file; keep both in sync)
- [x] No `${VAR}` tokens in `mcp.json`, so no `variables` schema is needed —
      auth is OAuth-on-first-use against mcp.usehalyard.ai
- [x] Logo committed at a safe relative path
- [x] Plugin README with usage instructions
- [ ] Public Git repo — this repo is already public
- [ ] Submit the repo URL at https://cursor.com/marketplace/publish
- [ ] Manual review by Cursor (updates are re-reviewed before each release
      goes live — factor this into release timing)

## License: resolved — MIT

Cursor's docs state **"all plugins must be open source."** This repo was
proprietary from PR #10 through v1.12.0; it was relicensed to MIT in the
Cursor-launch PR (decision: Al Hinds, 2026-08-21) to satisfy the marketplace
requirement. The plugin contains no secret sauce — skills, a rule, and a
pointer at the hosted MCP server; the moat is the service, not the manifest.
All three plugin manifests carry `"license": "MIT"` and the root `LICENSE` is
the standard MIT text.

## Local testing before submission

Symlink the plugin into Cursor's local plugin directory:

```bash
ln -s "$(pwd)/plugins/halyard" ~/.cursor/plugins/local/halyard
```

Known rough edge: local plugins may not auto-activate reliably
([cursor/plugin-template#4](https://github.com/cursor/plugin-template/issues/4)).
If skills don't appear, verify via a marketplace install once listed.

## Post-approval

- Update `apps/marketing/src/content/docs/docs/connect-agent/cursor.md` in
  the main repo to link the live marketplace listing URL.
- Announce in the changelog / socials with the listing link.
