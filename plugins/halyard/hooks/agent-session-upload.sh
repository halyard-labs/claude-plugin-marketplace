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
# HALYARD_TOKEN (environment, then the repo's .env) or `halyard login`, refuses
# login credentials scoped to an org other than the repo's .halyard.json binding,
# uploads the finished transcript at session end and sweeps missed ones at
# session start. Log: ~/.halyard/hooks.log.
ROOT="${CLAUDE_PROJECT_DIR:-${CODEX_CWD:-$PWD}}"
BIN="$ROOT/node_modules/.bin/halyard"
[ -x "$BIN" ] || BIN="$(command -v halyard 2>/dev/null || true)"
[ -n "$BIN" ] || exit 0
# Older CLI releases have no `hook` command (and answer `--help` for any word).
"$BIN" --help 2>/dev/null | grep -q '^  hook' || exit 0
exec "$BIN" hook "$@"
