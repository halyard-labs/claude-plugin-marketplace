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
halyard whoami             # user, org slug, and repo binding; fails if login is needed
cat .halyard.json          # repo binding, e.g. {"org": "acme"}
halyard sync --dry-run     # lists discovered transcripts; proves auth works
```

If all of these succeed, stop here. Otherwise continue from the first step
that failed.

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

Pick by environment, not by preference:

| Environment                                              | Use                                               |
| -------------------------------------------------------- | ------------------------------------------------- |
| Machine with a browser on the same host                  | `halyard login`                                   |
| Headless: SSH dev box, CI, container, or remote sandbox  | `HALYARD_TOKEN=sk_halyard_...` in the environment |

`halyard login` runs a browser OAuth flow (PKCE, loopback callback on
127.0.0.1) and times out after two minutes if no browser completes it, so do
**not** run it in a session with no browser on that machine; ask the user to
run it, or use a token. It writes `~/.halyard/credentials.json` (inside a repo
that is already bound, `~/.halyard/credentials/<orgId>.json` for that org).
The upload hooks use these when their org matches the repo's binding, and
refuse credentials for a different org.

For a token, the user mints an API key with `halyard api-keys create --name
"<repo>-<machine>"` (printed once; keys are bound to one org). `HALYARD_TOKEN`
takes precedence over stored credentials and never expires. The upload hook
also reads it from the plugin's **Halyard API key** option (Claude Code only —
a sensitive `userConfig` value prompted for when the plugin is enabled, stored
in the OS credential store, not shown in `/config`) and from the repo's
`.env`, so a token in any of those places is enough. Never commit the token or
paste it into chat; point the user at where to put it.

The machine also needs outbound HTTPS to `api.usehalyard.ai` (CLI) and
`mcp.usehalyard.ai` (MCP).

## 4. Bind and scaffold the repo

Run this after logging in. Users usually don't know their org slug (the web
app doesn't show it), so don't ask for it up front:

```bash
halyard setup --dry-run
halyard setup
```

Newer CLI releases bind the repo to the logged-in org when `--org` is
omitted, asking when the user belongs to several orgs. If the output does not
say `Bound this repo to "<slug>"` (CLI 0.3.0 and earlier skip binding without
`--org`, and any release skips it without a TTY for multi-org users), read the
slug from `halyard whoami` (the `Organization:` line) or `halyard orgs list`,
confirm it with the user if they belong to more than one org, and re-run:

```bash
halyard setup --org <slug>
```

What it writes:

| Target                        | File                                                                                   | Change                                                                                        |
| ----------------------------- | -------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Repo binding                  | `.halyard.json`                                                                        | `{"org": "<slug>"}`; `sync`, `push`, and the upload hooks refuse credentials for another org |
| Upload launcher               | `.halyard/hook.sh`                                                                     | Runs `halyard hook` for every client below                                                    |
| Claude Code (project)         | `.claude/settings.json`                                                                | Adds the `halyard-labs` marketplace, `enabledPlugins["halyard@halyard-labs"] = true`, and session hooks |
| Cursor (project)              | `.cursor/mcp.json`, `.cursor/hooks.json`                                               | Adds `mcpServers.halyard.url = https://mcp.usehalyard.ai` and session hooks                   |
| Codex                         | `~/.codex/config.toml` (if detected), `.codex/hooks.json`                              | Adds `[mcp_servers.halyard]` with the same URL, and session hooks                             |
| Gemini, Copilot, OpenCode, Grok | `.gemini/settings.json`, `.github/hooks/`, `.opencode/plugins/`, `.grok/hooks/`      | Session hooks                                                                                 |

`--no-hooks` skips the launcher and hook files; `--force` rebinds a repo
already bound to a different org. Re-running is idempotent. Commit the
generated files: that is what makes the plugin load, and sessions upload, for
every teammate who opens the repo. The plugin's own upload hook and the
repo's committed hooks can both run in Claude Code; `halyard hook` locks per
transcript, so they don't double-upload.

## 5. Verify

```bash
halyard --version
halyard whoami              # shows user, org, and the repo binding
halyard sync --dry-run      # lists discovered transcripts; proves auth works
```

Then confirm the MCP side in the same session:

```text
Use Halyard to tell me who I am.
```

Expect a `mcp__plugin_halyard_org-kb__whoami` call returning the user and
organization. The MCP connection has its own OAuth, separate from the CLI
login, so a first-use prompt there is expected even after `halyard login`.
After the next session ends, `~/.halyard/hooks.log` should show an upload.

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
- In a bound repo, `halyard sync` uploads only this repo's sessions; `--all`
  syncs every session on the machine.
- If `halyard --help` does not list a `hook` command, the installed CLI
  predates automatic upload (0.3.0, the current release, has it). Update it (`bun update @halyard/cli` or
  `npm i -g @halyard/cli@latest`) and, until then, run `halyard sync` by hand.

## Reporting back

Tell the user, in one short list, which of install / auth / scaffold / verify
you completed, which you could not (and why: no browser, no token, no network),
and the one command they need to run themselves. Do not describe every step
that already worked.
