---
name: setup-cli
description: >-
  Install, authenticate, and verify the Halyard CLI (@halyard/cli) so session
  transcripts upload and the repo is scaffolded for Claude Code, Cursor, and
  Codex. Use when the user asks to 'set up halyard', 'install the halyard cli',
  'halyard login', 'connect halyard', 'get halyard going', 'scaffold halyard',
  'sync my sessions', or asks why session uploads are not appearing in Halyard.
  Also use once, proactively, right after the plugin is installed in a repo
  that has no `halyard` binary yet. Skip if `halyard --version` already works
  and `halyard sync --dry-run` is authenticated.
---

# Set Up the Halyard CLI

> **Tool names.** The default names below are the halyard plugin's `org-kb` server as Claude Code exposes it: `mcp__plugin_halyard_org-kb__<tool>`. Older connections expose the same server under other prefixes — `mcp__halyard__<tool>` (standalone server added by the docs or `halyard setup`) and `mcp__ask-expert__<tool>` (claude.ai connector, Claude Code on the web) — and Codex and Cursor derive their own prefix from the `org-kb` key. These are aliases for one server, so match on the part after the last `__`: if the default name is not in your tool list, use whichever alias is present (search the deferred tool list for the bare name if needed) rather than concluding the tool is unavailable.

The plugin's MCP server works without the CLI. The CLI adds two things: it
scaffolds Halyard into a repo for every teammate, and it uploads coding-session
transcripts to Halyard. The plugin's SessionStart/SessionEnd hooks look for the
`halyard` binary and are a silent no-op without it, so nothing uploads until
this is done.

## 1. Check what is already there

```bash
# repo-local install (the hook checks here first), then PATH
ls node_modules/.bin/halyard 2>/dev/null || command -v halyard
halyard --version
halyard sync --dry-run     # fails with "Not authenticated" if login is needed
```

If all three succeed, stop here. Otherwise continue from the first step that
failed.

## 2. Install

Prefer a repo-local dev dependency: the upload hook resolves
`<repo>/node_modules/.bin/halyard` before falling back to a global install, so
a pinned dev dependency means every clone gets the same CLI with no extra step.

```bash
bun add -D @halyard/cli        # or: npm i -D @halyard/cli / pnpm add -D @halyard/cli
```

Alternatives, in order of preference:

- Global: `npm i -g @halyard/cli` (puts `halyard` on PATH for every repo)
- Zero-install, one-off: `bunx @halyard/cli <command>` or `pnpm dlx @halyard/cli <command>`

## 3. Authenticate

Two options. Pick by environment, not by preference:

| Environment                         | Use                                               |
| ----------------------------------- | ------------------------------------------------- |
| Interactive machine with a browser  | `halyard login`                                   |
| Headless, CI, or a remote sandbox   | `HALYARD_TOKEN=sk_halyard_...` in the environment |

`halyard login` runs a browser OAuth flow (PKCE, loopback callback on
127.0.0.1) and stores credentials in `~/.halyard/credentials.json` with mode
600. It times out after two minutes if no browser completes the flow, so do
**not** run it in a session with no browser; ask the user to run it on their
machine, or use a token.

`HALYARD_TOKEN` takes precedence over the stored credentials. An API key
(`sk_halyard_...`) never expires and is the right choice for CI. The
session-upload hook also reads `HALYARD_TOKEN` from the repo's `.env`, so a
token there is enough for uploads without a global login. Never commit the
token or paste it into chat; point the user at where to put it.

## 4. Scaffold the repo (optional)

`halyard setup` (alias `halyard init`) merges Halyard into existing config
without clobbering other entries. Preview first:

```bash
halyard setup --dry-run
halyard setup
```

What it writes:

| Target                    | File                     | Change                                                                                       |
| ------------------------- | ------------------------ | -------------------------------------------------------------------------------------------- |
| Claude Code (project)     | `.claude/settings.json`  | Adds the `halyard-labs` marketplace and sets `enabledPlugins["halyard@halyard-labs"] = true` |
| Cursor (project)          | `.cursor/mcp.json`       | Adds `mcpServers.halyard.url = https://mcp.usehalyard.ai`                                    |
| Codex (user, if detected) | `~/.codex/config.toml`   | Adds `[mcp_servers.halyard]` with `enabled = true` and the same URL                          |

If this skill is running, Claude Code already has the plugin for the current
user. Run `setup` anyway when the goal is repo-wide rollout: committing
`.claude/settings.json` is what makes the plugin load for every teammate who
opens the repo.

## 5. Verify

```bash
halyard --version
halyard sync --dry-run      # lists discovered transcripts; proves auth works
```

Then confirm the MCP side in the same session:

```text
Use Halyard to tell me who I am.
```

Expect a `mcp__plugin_halyard_org-kb__whoami` call returning the user and
organization. If the MCP call prompts for OAuth, that is expected on first use
and is separate from the CLI login.

## How uploads work after setup

- The plugin's `SessionStart` hook sweeps transcripts that never uploaded, and
  `SessionEnd` uploads the one that just finished, by handing the event to
  `halyard hook`. The hook exits 0 and does nothing when the CLI is missing,
  unauthenticated, or too old to have a `hook` command, so a missing upload is
  never a blocker for the agent. Check `~/.halyard/hooks.log` first when
  uploads seem to be missing.
- `halyard sync` uploads on demand. It discovers Claude Code transcripts under
  `~/.claude/projects/` and Codex transcripts under `~/.codex/sessions/`; filter
  with `--provider claude` or `--provider codex`. `halyard push <path>` uploads
  a single file.
- If `halyard --help` does not list a `hook` command, the installed CLI
  predates automatic upload. Update it (`bun update @halyard/cli` or
  `npm i -g @halyard/cli@latest`) and, until then, run `halyard sync` by hand.

## Reporting back

Tell the user, in one short list, which of install / auth / scaffold / verify
you completed, which you could not (and why: no browser, no token, no network),
and the one command they need to run themselves. Do not describe every step
that already worked.
