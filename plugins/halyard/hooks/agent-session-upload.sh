#!/usr/bin/env bash
# Halyard agent-session upload hook.
#
# One entry point for every coding-agent client's lifecycle hooks. At session
# end it uploads the transcript that just finished; at session start it sweeps
# this repo's earlier transcripts that never made it up (crashes, killed
# terminals, sessions that ended before the hook existed). Uploads go through
# the `halyard` CLI (`halyard push` / `halyard sync`), so every agent session
# lands in the org's knowledge base and work-event stream.
#
# Wired from (all call this same script):
#   .claude/settings.json          SessionStart / SessionEnd    --client claude
#   .codex/hooks.json              SessionStart / SessionEnd    --client codex
#   .cursor/hooks.json             sessionStart / sessionEnd    --client cursor
#   .gemini/settings.json          SessionStart / SessionEnd    --client gemini
#   .github/hooks/*.json           sessionStart / sessionEnd    --client copilot
#   .opencode/plugins/*.ts         session.idle                 --client opencode
# This is the halyard plugin's copy, invoked from hooks/hooks.json for any
# repo that enables the plugin (Claude Code and Codex, which loads Claude-style
# plugin hooks). Canonical source: scripts/agent-session-upload.sh in
# github.com/halyard-labs/halyard — keep the two in step.
#
# Contract:
#   * Never blocks or fails the agent. Always exits 0. Nothing is written to
#     stdout (several clients parse hook stdout as JSON); everything goes to
#     ~/.halyard/hooks.log.
#   * No-op unless the `halyard` binary AND credentials are available.
#   * Idempotent. The CLI's sync-state (content hash) plus a per-file lock make
#     it safe for several hooks (repo-level + plugin) to fire for one transcript.
#   * Repo-scoped. Only transcripts recorded for this repo are swept, so a
#     developer working across orgs never uploads repo A's sessions with repo
#     B's credentials.
#
# Auth resolution (first hit wins):
#   1. HALYARD_TOKEN in the environment      (cloud / CI: set per environment)
#   2. HALYARD_TOKEN in <repo>/.env          (local, per-repo API key)
#   3. ~/.halyard/credentials.json           (`halyard login`)
# Optional: HALYARD_API_URL to target a non-production API,
#           HALYARD_ORG_SLUG / --org to refuse login credentials for another org,
#           HALYARD_SESSION_UPLOAD=0 to disable the hook entirely.
#
# Why session end and not every turn: the ingest endpoint keeps the FIRST
# upload it sees for a session id, so uploading a growing transcript after
# each turn would freeze the session at turn one. Until the API supports
# re-upload, the end-of-session transcript is the one that gets sent, and
# the start-of-session sweep picks up anything a crash or kill left behind.
#
# Usage:
#   agent-session-upload.sh [--client <name>] [--event start|end] [--org <slug>]
#                           [--transcript <path>] [--detach] [--dry-run]
# Hook JSON (session_id, transcript_path, cwd, hook_event_name) is read from
# stdin when present. --client is auto-detected from the transcript path or
# the client's environment when omitted. --detach runs the end-of-session
# upload in a background process for clients whose SessionEnd hook budget is
# too short to wait for the network (Codex caps it at 3s).

set -u

HALYARD_DIR="${HALYARD_DIR:-$HOME/.halyard}"
LOG_FILE="$HALYARD_DIR/hooks.log"
SYNC_STATE="$HALYARD_DIR/sync-state.json"
LOCKS_DIR="$HALYARD_DIR/locks"

CLIENT=""
EVENT=""
TRANSCRIPT_ARG=""
DRY_RUN=0
DETACH=0
ORG_SLUG="${HALYARD_ORG_SLUG:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --client) CLIENT="${2:-}"; shift 2 ;;
    --event) EVENT="${2:-}"; shift 2 ;;
    --transcript) TRANSCRIPT_ARG="${2:-}"; shift 2 ;;
    --org) ORG_SLUG="${2:-}"; shift 2 ;;
    --detach) DETACH=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,55p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) shift ;;
  esac
done

[ "${HALYARD_SESSION_UPLOAD:-1}" = "0" ] && exit 0

mkdir -p "$HALYARD_DIR" "$LOCKS_DIR" 2>/dev/null || exit 0
# Keep the log bounded (~1 MB) — it is append-only otherwise.
if [ -f "$LOG_FILE" ] && [ "$(wc -c <"$LOG_FILE" | tr -d ' ')" -gt 1048576 ]; then
  tail -c 262144 "$LOG_FILE" >"$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

log() {
  printf '%s [%s/%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${CLIENT:-?}" "${EVENT:-?}" "$*" >>"$LOG_FILE" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Hook input. Claude, Codex, Gemini, Cursor and Copilot all pipe a JSON object
# on stdin; field names differ slightly per client, so pick from a list.
# ---------------------------------------------------------------------------
INPUT=""
if [ ! -t 0 ]; then
  INPUT=$(cat 2>/dev/null || true)
fi

H_EVENT=""
H_SESSION=""
H_TRANSCRIPT=""
H_CWD=""
if [ -n "$INPUT" ] && command -v node >/dev/null 2>&1; then
  PARSED=$(HOOK_INPUT="$INPUT" node -e '
    let o = {}
    try { o = JSON.parse(process.env.HOOK_INPUT || "") } catch {}
    if (!o || typeof o !== "object") o = {}
    const pick = (keys) => {
      for (const k of keys) { const v = o[k]; if (typeof v === "string" && v) return v }
      return ""
    }
    // Cursor sends workspace_roots as an array; every other client sends cwd.
    const roots = Array.isArray(o.workspace_roots) ? o.workspace_roots : []
    const rows = [
      pick(["hook_event_name", "event", "type"]),
      pick(["session_id", "sessionId", "conversation_id", "thread_id", "threadId"]),
      pick(["transcript_path", "transcriptPath"]),
      pick(["cwd", "workspace_root", "project_dir"]) || (typeof roots[0] === "string" ? roots[0] : ""),
    ]
    process.stdout.write(rows.map((r) => r.replace(/[\r\n]/g, " ")).join("\n"))
  ' 2>/dev/null || true)
  H_EVENT=$(printf '%s\n' "$PARSED" | sed -n '1p')
  H_SESSION=$(printf '%s\n' "$PARSED" | sed -n '2p')
  H_TRANSCRIPT=$(printf '%s\n' "$PARSED" | sed -n '3p')
  H_CWD=$(printf '%s\n' "$PARSED" | sed -n '4p')
fi
[ -n "$TRANSCRIPT_ARG" ] && H_TRANSCRIPT="$TRANSCRIPT_ARG"
# Cursor also exports the transcript path as an env var.
[ -z "$H_TRANSCRIPT" ] && [ -n "${CURSOR_TRANSCRIPT_PATH:-}" ] && H_TRANSCRIPT="$CURSOR_TRANSCRIPT_PATH"

# Normalise the event to start|end. Unknown events are ignored.
if [ -z "$EVENT" ]; then
  case "$H_EVENT" in
    SessionStart|sessionStart|session_start|session.start) EVENT=start ;;
    SessionEnd|sessionEnd|session_end|session.end|Stop|stop|session.idle|agent-turn-complete) EVENT=end ;;
    *) EVENT="" ;;
  esac
fi
[ -n "$EVENT" ] || exit 0

# Client auto-detection: transcript path first, then the host's environment.
if [ -z "$CLIENT" ]; then
  case "$H_TRANSCRIPT" in
    */.claude/*) CLIENT=claude ;;
    */.codex/*) CLIENT=codex ;;
    */.cursor/*) CLIENT=cursor ;;
    */.gemini/*) CLIENT=gemini ;;
    */.copilot/*) CLIENT=copilot ;;
  esac
fi
if [ -z "$CLIENT" ]; then
  # Cursor sets CLAUDE_PROJECT_DIR as a compatibility alias, so test it first.
  if [ -n "${CURSOR_PROJECT_DIR:-}${CURSOR_VERSION:-}" ]; then CLIENT=cursor
  elif [ -n "${GEMINI_PROJECT_DIR:-}" ]; then CLIENT=gemini
  elif [ -n "${CODEX_CWD:-}${CODEX_HOME:-}" ]; then CLIENT=codex
  elif [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then CLIENT=claude
  else CLIENT=claude
  fi
fi

# ---------------------------------------------------------------------------
# Project root. Hooks run with cwd set to the project by every client, but be
# explicit: env from the host, then the hook payload, then git, then $PWD.
# ---------------------------------------------------------------------------
resolve_root() {
  local candidate
  for candidate in "${HALYARD_PROJECT_ROOT:-}" "${CLAUDE_PROJECT_DIR:-}" "${CURSOR_PROJECT_DIR:-}" "${GEMINI_PROJECT_DIR:-}" "${CODEX_CWD:-}" "$H_CWD" "$PWD"; do
    [ -n "$candidate" ] && [ -d "$candidate" ] || continue
    git -C "$candidate" rev-parse --show-toplevel 2>/dev/null && return 0
    printf '%s\n' "$candidate"
    return 0
  done
  printf '%s\n' "$PWD"
}
PROJECT_ROOT=$(resolve_root)

# ---------------------------------------------------------------------------
# CLI binary: the repo's pinned @halyard/cli first, then a global install.
# ---------------------------------------------------------------------------
HALYARD_BIN=""
if [ -x "$PROJECT_ROOT/node_modules/.bin/halyard" ]; then
  HALYARD_BIN="$PROJECT_ROOT/node_modules/.bin/halyard"
elif command -v halyard >/dev/null 2>&1; then
  HALYARD_BIN=$(command -v halyard)
fi
if [ -z "$HALYARD_BIN" ]; then
  log "skip: halyard CLI not found (pnpm install, or npm i -g @halyard/cli)"
  exit 0
fi

# ---------------------------------------------------------------------------
# Auth. A token in <repo>/.env lets each repo carry its own org's key.
# ---------------------------------------------------------------------------
if [ -z "${HALYARD_TOKEN:-}" ] && [ -f "$PROJECT_ROOT/.env" ]; then
  ENV_TOKEN=$(grep -E '^[[:space:]]*(export[[:space:]]+)?HALYARD_TOKEN=' "$PROJECT_ROOT/.env" 2>/dev/null | tail -1 | sed -E 's/^[[:space:]]*(export[[:space:]]+)?HALYARD_TOKEN=//; s/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/' | tr -d '\r')
  if [ -n "$ENV_TOKEN" ]; then
    export HALYARD_TOKEN="$ENV_TOKEN"
  fi
fi
if [ -z "${HALYARD_TOKEN:-}" ] && [ ! -s "$HALYARD_DIR/credentials.json" ]; then
  log "skip: not authenticated (run \`halyard login\`, or set HALYARD_TOKEN in the environment or $PROJECT_ROOT/.env)"
  exit 0
fi
# The repo's .env can also declare its org (scripts/halyard-token-setup.sh
# writes it next to the token), so the plugin copy of this script — which has
# no --org on its command line — still gets the guard.
if [ -z "$ORG_SLUG" ] && [ -f "$PROJECT_ROOT/.env" ]; then
  ORG_SLUG=$(grep -E '^[[:space:]]*(export[[:space:]]+)?HALYARD_ORG_SLUG=' "$PROJECT_ROOT/.env" 2>/dev/null | tail -1 | sed -E 's/^[[:space:]]*(export[[:space:]]+)?HALYARD_ORG_SLUG=//; s/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/' | tr -d '\r')
fi

API_ARGS=()
if [ -n "${HALYARD_API_URL:-}" ]; then
  API_ARGS=(--api-url "$HALYARD_API_URL")
fi

# ---------------------------------------------------------------------------
# Org guard. `halyard login` credentials are scoped to whichever org the user
# last switched to, and one account can belong to several orgs. A repo that
# declares its org (--org <slug>, or HALYARD_ORG_SLUG) refuses to upload with
# credentials for a different one, instead of quietly filing the session under
# the wrong company. API keys are minted per org, so only login credentials
# are checked.
# ---------------------------------------------------------------------------
if [ -n "$ORG_SLUG" ] && [ -z "${HALYARD_TOKEN:-}" ] && [ -s "$HALYARD_DIR/credentials.json" ] && command -v node >/dev/null 2>&1; then
  CURRENT_ORG=$(HALYARD_CREDS="$HALYARD_DIR/credentials.json" HALYARD_API="${HALYARD_API_URL:-}" node -e '
    const fs = require("fs")
    let c = {}
    try { c = JSON.parse(fs.readFileSync(process.env.HALYARD_CREDS, "utf8")) } catch { process.exit(0) }
    const api = process.env.HALYARD_API || c.apiUrl || "https://api.usehalyard.ai"
    const ctrl = new AbortController()
    setTimeout(() => ctrl.abort(), 8000)
    fetch(api + "/api/v1/me", { headers: { Authorization: "Bearer " + c.accessToken }, signal: ctrl.signal })
      .then((r) => (r.ok ? r.json() : null))
      .then((j) => { const s = j && j.organization && j.organization.slug; if (s) process.stdout.write(String(s)) })
      .catch(() => {})
  ' 2>/dev/null)
  if [ -z "$CURRENT_ORG" ]; then
    log "org check: could not resolve the current org (token expired or API unreachable); uploading anyway"
  elif [ "$CURRENT_ORG" != "$ORG_SLUG" ]; then
    log "skip: credentials are for org '$CURRENT_ORG' but this repo uploads to '$ORG_SLUG' (run \`halyard orgs switch $ORG_SLUG\`, or set HALYARD_TOKEN to a $ORG_SLUG API key in $PROJECT_ROOT/.env)"
    exit 0
  fi
fi

# ---------------------------------------------------------------------------
# Upload primitives.
# ---------------------------------------------------------------------------
sha16() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -c1-16
  else sha256sum "$1" | cut -c1-16
  fi
}

# Mirrors the CLI's sync-state check (sha256 prefix of the file bytes).
already_uploaded() {
  [ -f "$SYNC_STATE" ] || return 1
  command -v node >/dev/null 2>&1 || return 1
  HALYARD_SYNC_STATE="$SYNC_STATE" node -e '
    let s = {}
    try { s = JSON.parse(require("fs").readFileSync(process.env.HALYARD_SYNC_STATE, "utf8")) } catch {}
    const e = s && s.files && s.files[process.argv[1]]
    process.exit(e && e.hash === process.argv[2] ? 0 : 1)
  ' "$1" "$(sha16 "$1")" 2>/dev/null
}

CREATED_LOCKS=()
cleanup_locks() {
  local d
  for d in ${CREATED_LOCKS[@]+"${CREATED_LOCKS[@]}"}; do rmdir "$d" 2>/dev/null || true; done
}
trap cleanup_locks EXIT

# push_file <path> <provider>
# The session id is the file name without extension — the same rule the CLI's
# `halyard sync` uses, so hook uploads and later manual syncs dedupe together.
push_file() {
  local file="$1" provider="$2"
  [ -s "$file" ] || return 0
  if already_uploaded "$file"; then
    log "skip (already uploaded): $file"
    return 0
  fi
  local session_id lock out rc
  session_id=$(basename "$file")
  session_id="${session_id%.*}"
  lock="$LOCKS_DIR/$(printf '%s' "$file" | shasum | cut -c1-16)"
  if ! mkdir "$lock" 2>/dev/null; then
    # A stale lock (crashed hook) is reclaimed after 10 minutes.
    if [ -n "$(find "$lock" -maxdepth 0 -mmin +10 2>/dev/null)" ]; then
      rmdir "$lock" 2>/dev/null; mkdir "$lock" 2>/dev/null || return 0
    else
      log "skip (another hook is uploading): $file"
      return 0
    fi
  fi
  CREATED_LOCKS+=("$lock")
  if [ "$DRY_RUN" = "1" ]; then
    log "dry-run: would push [$provider] $file ($(wc -c <"$file" | tr -d ' ') bytes)"
    rmdir "$lock" 2>/dev/null
    return 0
  fi
  out=$("$HALYARD_BIN" ${API_ARGS[@]+"${API_ARGS[@]}"} push "$file" --provider "$provider" --session-id "$session_id" 2>&1)
  rc=$?
  rmdir "$lock" 2>/dev/null
  log "push[$provider] rc=$rc $file :: $(printf '%s' "$out" | tr '\n' ' ' | cut -c1-300)"
}

# sync_provider <provider>
# Machine-wide fallback for clients whose transcripts we cannot scope to this
# repo from the hook payload. Requires a CLI version that knows the provider.
sync_provider() {
  local provider="$1" out rc
  if [ "$DRY_RUN" = "1" ]; then
    out=$("$HALYARD_BIN" ${API_ARGS[@]+"${API_ARGS[@]}"} sync --provider "$provider" --dry-run 2>&1)
  else
    out=$("$HALYARD_BIN" ${API_ARGS[@]+"${API_ARGS[@]}"} sync --provider "$provider" 2>&1)
  fi
  rc=$?
  log "sync[$provider] rc=$rc :: $(printf '%s' "$out" | tail -1 | cut -c1-300)"
}

# Claude keeps subagent transcripts beside the main one:
#   <dir>/<session>.jsonl  +  <dir>/<session>/subagents/agent-*.jsonl
push_claude_session() {
  local file="$1" dir sid sub
  dir=$(dirname "$file")
  sid=$(basename "$file" .jsonl)
  push_file "$file" claude
  for sub in "$dir/$sid"/subagents/*.jsonl; do
    [ -e "$sub" ] && push_file "$sub" claude
  done
}

path_slug() { # /Users/x/repo -> -Users-x-repo   (Claude)   or   Users-x-repo (Cursor)
  printf '%s' "$1" | sed -e 's#[/.]#-#g'
}

# ---------------------------------------------------------------------------
# Per-client discovery of this repo's transcripts (used by the start sweep and
# by end events whose payload carries no transcript path).
# ---------------------------------------------------------------------------
sweep_claude() {
  local dir f
  if [ -n "$H_TRANSCRIPT" ]; then dir=$(dirname "$H_TRANSCRIPT")
  else dir="$HOME/.claude/projects/$(path_slug "$PROJECT_ROOT")"
  fi
  [ -d "$dir" ] || { log "no claude transcripts at $dir"; return 0; }
  for f in "$dir"/*.jsonl; do
    [ -e "$f" ] || continue
    # Skip the live session: it is uploaded at SessionEnd (first upload wins server-side).
    [ -n "$H_SESSION" ] && [ "$(basename "$f" .jsonl)" = "$H_SESSION" ] && continue
    push_claude_session "$f"
  done
}

# Codex rollouts record the launch cwd in their first line; match this repo
# (and its worktrees) by prefix.
sweep_codex() {
  local dir="$HOME/.codex/sessions" f
  [ -d "$dir" ] || { log "no codex sessions dir"; return 0; }
  find "$dir" -type f -name 'rollout-*.jsonl' 2>/dev/null | while IFS= read -r f; do
    if head -c 6000 "$f" 2>/dev/null | grep -qE "\"cwd\":\"$(printf '%s' "$PROJECT_ROOT" | sed 's/[][\\.*^$|?+(){}]/\\&/g')(/|\")"; then
      printf '%s\n' "$f"
    fi
  done | while IFS= read -r f; do
    # Skip the live session on the start sweep (rollout-<timestamp>-<id>.jsonl).
    if [ "$EVENT" = start ] && [ -n "$H_SESSION" ]; then
      case "$(basename "$f")" in *"-$H_SESSION.jsonl") continue ;; esac
    fi
    push_file "$f" codex
  done
}

# Cursor writes agent transcripts per project under
#   ~/.cursor/projects/<path-slug>/agent-transcripts/<conversation>/<conversation>.jsonl
sweep_cursor() {
  local slug dir f
  slug=$(path_slug "$PROJECT_ROOT" | sed 's/^-//')
  dir="$HOME/.cursor/projects/$slug/agent-transcripts"
  [ -d "$dir" ] || { log "no cursor transcripts at $dir"; return 0; }
  for f in "$dir"/*/*.jsonl; do
    [ -e "$f" ] || continue
    push_file "$f" cursor
  done
}

# Grok Build keeps sessions under ~/.grok/sessions/; the hook payload carries
# only the session id, so match on it. Layout is not officially documented —
# best effort, uploaded as provider "other" (no Halyard parser yet).
sweep_grok() {
  local dir="$HOME/.grok/sessions" f
  [ -d "$dir" ] || { log "no grok sessions dir"; return 0; }
  [ -n "$H_SESSION" ] || { log "grok: no session id in payload; nothing to upload"; return 0; }
  find "$dir" -type f \( -name "*$H_SESSION*.json" -o -name "*$H_SESSION*.jsonl" \) 2>/dev/null | while IFS= read -r f; do
    push_file "$f" other
  done
}

# Amp caches threads locally as T-<id>.json under ~/.local/share/amp (or
# AMP_DATA_DIR). Only the thread named by the plugin event is uploaded —
# there is no per-repo marker to scope a wider sweep. Provider "other".
sweep_amp() {
  local dir="${AMP_DATA_DIR:-$HOME/.local/share/amp}" f
  [ -d "$dir" ] || { log "no amp data dir"; return 0; }
  [ -n "$H_SESSION" ] || { log "amp: no thread id in payload; nothing to upload"; return 0; }
  find "$dir" -type f -name "$H_SESSION.json" 2>/dev/null | while IFS= read -r f; do
    push_file "$f" other
  done
}

sweep_for_client() {
  case "$CLIENT" in
    claude) sweep_claude ;;
    codex) sweep_codex ;;
    cursor) sweep_cursor ;;
    grok) sweep_grok ;;
    amp) sweep_amp ;;
    gemini|opencode|copilot) sync_provider "$CLIENT" ;;
    *) log "no sweep strategy for client '$CLIENT'" ;;
  esac
}

# Ingest provider name for a client. Clients without a Halyard parser upload
# as "other": the raw log is kept in R2 and re-processed once a parser lands.
provider_for_client() {
  case "$1" in
    claude|codex|cursor|gemini|opencode|copilot) printf '%s' "$1" ;;
    *) printf 'other' ;;
  esac
}

# ---------------------------------------------------------------------------
# Main.
# ---------------------------------------------------------------------------
log "root=$PROJECT_ROOT bin=$HALYARD_BIN transcript=${H_TRANSCRIPT:-<none>} session=${H_SESSION:-<none>}"

upload_ended_session() {
  if [ -n "$H_TRANSCRIPT" ] && [ -s "$H_TRANSCRIPT" ]; then
    case "$CLIENT" in
      claude) push_claude_session "$H_TRANSCRIPT" ;;
      *) push_file "$H_TRANSCRIPT" "$(provider_for_client "$CLIENT")" ;;
    esac
  elif [ "$CLIENT" = codex ] && [ -n "$H_SESSION" ]; then
    # Rollout files end in the thread id: rollout-<timestamp>-<id>.jsonl
    local f
    f=$(find "$HOME/.codex/sessions" -type f -name "rollout-*-$H_SESSION.jsonl" 2>/dev/null | head -1)
    if [ -n "$f" ]; then push_file "$f" codex; else sweep_for_client; fi
  else
    sweep_for_client
  fi
}

case "$EVENT" in
  end)
    if [ "$DETACH" = "1" ]; then
      (
        upload_ended_session
        log "detached end upload finished"
      ) </dev/null >>"$LOG_FILE" 2>&1 &
      disown 2>/dev/null || true
    else
      upload_ended_session
    fi
    ;;
  start)
    # Sweep in the background so session start is never delayed. Detach every
    # fd — the host waits for the hook's stdout to close.
    (
      sweep_for_client
      log "start sweep finished"
    ) </dev/null >>"$LOG_FILE" 2>&1 &
    disown 2>/dev/null || true
    ;;
esac

# Gemini CLI blocks unless a hook prints JSON on stdout.
[ "$CLIENT" = gemini ] && printf '{}\n'
exit 0
