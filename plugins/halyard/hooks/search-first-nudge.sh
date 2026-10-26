#!/bin/bash
# PreToolUse hook: once per session, refuse the first investigative tool call
# if no knowledge-base search has happened yet, so the agent decides whether
# to search before it starts reading code, delegating, or researching.
#
# A PreToolUse `additionalContext` is delivered next to the tool result, i.e.
# after the call it was meant to steer, so an advisory nudge lands too late.
# `permissionDecision: "deny"` skips the call and shows the reason first. The
# reason is a decision rule with an explicit no-op branch (retry unchanged),
# so a trivial task or a session without the KB tools costs one retried call.
#
# Search state lives in a per-session file: a search_knowledge or
# explore_knowledge call under any MCP prefix (org-kb, halyard, ask-expert)
# marks the session as searched, and the deny marks it as nudged. The
# transcript is only a fallback for sessions that searched before this hook
# version, and only its `tool_use` entries count: transcripts also carry
# tool schemas (prompt_snapshot attachments) with the same `"name":"..."`
# text. Stays silent on any error.

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

[ -n "$SESSION_ID" ] || exit 0
STATE_DIR="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/halyard}/search-first"
STATE_FILE="$STATE_DIR/$(printf '%s' "$SESSION_ID" | tr -c 'A-Za-z0-9_-' '_')"

mark() {
  mkdir -p "$STATE_DIR" 2>/dev/null && printf '%s\n' "$1" > "$STATE_FILE" 2>/dev/null
}

case "$TOOL_NAME" in
  mcp__*__search_knowledge|mcp__*__explore_knowledge)
    mark searched
    exit 0
    ;;
  Bash|Read|Grep|Glob|Agent|Task|WebSearch|WebFetch|Edit|Write|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

# Already searched, or already nudged, this session.
[ -f "$STATE_FILE" ] && exit 0

# Searched before this hook version started tracking state.
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ] &&
  grep -qE '"type":"tool_use","id":"[^"]*","name":"mcp__[^"]*__(search_knowledge|explore_knowledge)"' "$TRANSCRIPT_PATH"; then
  mark searched
  exit 0
fi

# Without a writable state file the deny would repeat on every call.
mark nudged || exit 0

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Paused once: no knowledge-base search has happened in this session yet. If this task touches existing systems, past decisions, or prior work, first call mcp__plugin_halyard_org-kb__search_knowledge with a topical query (the same tool may be mounted as mcp__halyard__search_knowledge or mcp__ask-expert__search_knowledge; if it is deferred, load it with ToolSearch), then continue. If the task is trivial or no knowledge-base tool is available, retry this exact call unchanged. This will not be asked again in this session."
  }
}
EOF
