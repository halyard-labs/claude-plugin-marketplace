#!/bin/sh
# Halyard plugin: session upload hook.
#
# Forwards the host's SessionStart / SessionEnd events to `halyard hook`, the
# uploader in the Halyard CLI (@halyard/cli), when the CLI is available:
#   1. <repo>/node_modules/.bin/halyard   (repos that pin @halyard/cli)
#   2. `halyard` on PATH                  (npm i -g @halyard/cli)
# and exits 0 otherwise so the agent is never blocked. Works for Claude Code
# and for Codex, which loads Claude-style plugin hooks.
#
# `halyard hook` reads the hook payload from stdin, resolves the repo root
# (CLAUDE_PROJECT_DIR / CODEX cwd / payload cwd), authenticates via
# HALYARD_TOKEN (environment, then the plugin's `halyard_token` option, then
# the repo's .env) or `halyard login`, refuses login credentials scoped to an
# org other than the repo's .halyard.json binding, uploads the finished
# transcript at session end and sweeps missed ones at session start.
# Log: ~/.halyard/hooks.log.
#
# The `halyard_token` option is declared as sensitive `userConfig` in
# .claude-plugin/plugin.json: Claude Code prompts for it when the plugin is
# enabled, keeps it in the OS credential store, and exports it to hook
# processes as CLAUDE_PLUGIN_OPTION_HALYARD_TOKEN. An explicit HALYARD_TOKEN in
# the environment (CI, sandboxes) still wins; the option is a fallback for
# machines that never ran `halyard login`. Codex does not read userConfig, so
# the variable is simply absent there.
if [ -z "${HALYARD_TOKEN:-}" ] && [ -n "${CLAUDE_PLUGIN_OPTION_HALYARD_TOKEN:-}" ]; then
  HALYARD_TOKEN="$CLAUDE_PLUGIN_OPTION_HALYARD_TOKEN"
  export HALYARD_TOKEN
fi
ROOT="${CLAUDE_PROJECT_DIR:-${CODEX_CWD:-$PWD}}"
BIN="$ROOT/node_modules/.bin/halyard"
[ -x "$BIN" ] || BIN="$(command -v halyard 2>/dev/null || true)"
[ -n "$BIN" ] || exit 0
# Older CLI releases have no `hook` command (and answer `--help` for any word).
"$BIN" --help 2>/dev/null | grep -q '^  hook' || exit 0
exec "$BIN" hook "$@"
