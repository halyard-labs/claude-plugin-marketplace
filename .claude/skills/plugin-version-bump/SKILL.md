---
name: plugin-version-bump
description: >-
  Bump plugin version on every commit. ALWAYS use this skill when committing
  changes to this repository. The Claude Code plugin cache keys on the version
  field in plugin.json — if the version isn't bumped, users get stale cached
  plugins missing new features, hooks, and fixes. Trigger on: /commit, "commit",
  "git commit", or any action that creates a git commit.
---

# Plugin Version Bump

Before every commit in this repo, bump the `version` field in each changed plugin's `plugin.json`.

## Why

Claude Code caches plugins by version string. If you push changes but keep the same version, users' caches serve the old plugin until they manually clear it. Bumping the version ensures fresh installs always get the latest.

## Process

1. Identify which `plugins/*/` directories have staged changes (use `git diff --cached --name-only`)
2. For each affected plugin, read its `.claude-plugin/plugin.json`
3. Bump the patch version (e.g. `1.0.0` → `1.0.1`, `1.2.3` → `1.2.4`)
4. Update the matching plugin entry's `version` field in the root `.claude-plugin/marketplace.json` to the same new version
5. Stage both the updated `plugin.json` and `.claude-plugin/marketplace.json`
6. Proceed with the commit

## Rules

- **Always bump patch** unless the commit message explicitly says `BREAKING:` (bump major) or adds new user-facing features like skills/hooks (bump minor)
- If multiple plugins changed, bump each independently
- Never skip the bump — even for docs-only changes, since docs are bundled in the plugin
