#!/bin/bash
# Stop hook: nudge to decide whether the session produced durable knowledge
# worth capturing with summarize_work.
#
# A Stop hook has no advisory channel: the only way to put text in front of
# the model is `decision: "block"`, which forces one more turn. So the reason
# below is written as a decision rule with an explicit no-op branch (end the
# turn, no message, no question to the user), not as an invitation. The hook
# cannot judge content — the gate is a cheap proxy that counts substantive
# tool calls (edits, subagents, web research).
#
# Counting starts from the latest marker: the last nudge or the last
# summarize_work/upsert_knowledge call, whichever is later. The first nudge
# needs one substantive call; after a nudge or a capture, the nudge re-arms
# once REARM_THRESHOLD more have happened, so a long session that logged a
# spec early, or declined an early nudge, is still asked about the work that
# followed. Stays silent on any error.
#
# Tool calls are matched on the transcript's `tool_use` entries only.
# Transcripts also carry tool schemas (prompt_snapshot attachments) with the
# same `"name":"..."` text, which a bare name match mistakes for calls.

command -v jq >/dev/null 2>&1 || exit 0

REARM_THRESHOLD=10
NUDGE_PHRASE='decide silently whether this session produced durable knowledge'
TOOL_USE='"type":"tool_use","id":"[^"]*","name":'

INPUT=$(cat)

# Already continuing because of this hook — let the session end.
ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$ACTIVE" = "true" ]; then
  exit 0
fi

TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

# Per-session record of the transcript line count at the last nudge.
STATE_FILE=""
if [ -n "$SESSION_ID" ]; then
  STATE_DIR="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/halyard}/stop-nudge"
  STATE_FILE="$STATE_DIR/$(printf '%s' "$SESSION_ID" | tr -c 'A-Za-z0-9_-' '_')"
fi

TOTAL_LINES=$(wc -l < "$TRANSCRIPT_PATH" | tr -d ' ')

record_marker() {
  [ -n "$STATE_FILE" ] || return 0
  mkdir -p "$(dirname "$STATE_FILE")" 2>/dev/null &&
    printf '%s\n' "$TOTAL_LINES" > "$STATE_FILE" 2>/dev/null
}

# Outcomes captured in the turn that is ending. The transcript file is written
# asynchronously and may not yet contain this turn's tool calls, so check the
# documented `last_assistant_message` field first: the log-work skill ends a
# logged session's final message with a "Logged to Halyard:" line.
LAST_MESSAGE=$(printf '%s' "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)
case "$LAST_MESSAGE" in
  *"Logged to Halyard:"*) record_marker; exit 0 ;;
esac

# Last nudge: from the state file, else (state unwritable, or a session that
# started on an older version) the last transcript line carrying the nudge.
NUDGE_LINE=0
if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
  NUDGE_LINE=$(tr -dc '0-9' < "$STATE_FILE")
else
  NUDGE_LINE=$(grep -nF "$NUDGE_PHRASE" "$TRANSCRIPT_PATH" | tail -n 1 | cut -d: -f1)
fi
NUDGE_LINE=${NUDGE_LINE:-0}

# Last capture under any MCP prefix.
CAPTURE_LINE=$(grep -nE "${TOOL_USE}\"mcp__[^\"]*__(summarize_work|upsert_knowledge)\"" "$TRANSCRIPT_PATH" | tail -n 1 | cut -d: -f1)
CAPTURE_LINE=${CAPTURE_LINE:-0}

MARKER=$NUDGE_LINE
[ "$CAPTURE_LINE" -gt "$MARKER" ] && MARKER=$CAPTURE_LINE

# Substantive calls since the marker. `Task` is the pre-2.1.63 name of the
# subagent tool, kept for older clients.
ACTIVITY=$(tail -n +"$((MARKER + 1))" "$TRANSCRIPT_PATH" |
  grep -oE "${TOOL_USE}\"(Edit|Write|MultiEdit|NotebookEdit|Agent|Task|WebSearch|WebFetch)\"" |
  wc -l | tr -d ' ')

THRESHOLD=1
[ "$MARKER" -gt 0 ] && THRESHOLD=$REARM_THRESHOLD
if [ "${ACTIVITY:-0}" -lt "$THRESHOLD" ]; then
  exit 0
fi

record_marker

cat <<'JSON'
{
  "decision": "block",
  "reason": "Before finishing, decide silently whether this session produced durable knowledge: code changes with non-obvious reasoning, a decision and its rationale, debugging findings, research conclusions, or a reusable answer from the user. Judge the work since your last capture or the last time you were asked this, not the whole session again. If it did, call mcp__plugin_halyard_org-kb__summarize_work (the same tool may be mounted as mcp__halyard__summarize_work or mcp__ask-expert__summarize_work) with the most appropriate entry_type (WORK_OUTPUT, DECISION, PROCESS, or CONTEXT), then end your turn. If it did not, end your turn immediately with no further message: do not ask the user whether to log, do not summarise the session, and do not explain why nothing was logged."
}
JSON
