#!/bin/bash
# Stop hook: one-time nudge to decide whether the session produced durable
# knowledge worth capturing with summarize_work.
#
# A Stop hook has no advisory channel: the only way to put text in front of
# the model is `decision: "block"`, which forces one more turn. So the reason
# below is written as a decision rule with an explicit no-op branch (end the
# turn, no message, no question to the user), not as an invitation. The hook
# cannot judge content — the gate is a cheap proxy that only rules out
# sessions with no sign of substantive activity (no edits, subagents, or web
# research). Fires at most once per session (stop_hook_active guard plus a
# transcript check for the nudge text, so declining it doesn't re-trigger at
# later stops) and stays silent on any error.

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)

# Already continuing because of this hook — let the session end.
ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$ACTIVE" = "true" ]; then
  exit 0
fi

# Outcomes captured in the turn that is ending. The transcript file is written
# asynchronously and may not yet contain this turn's tool calls, so check the
# documented `last_assistant_message` field first: the log-work skill ends a
# logged session's final message with a "Logged to Halyard:" line.
LAST_MESSAGE=$(printf '%s' "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)
case "$LAST_MESSAGE" in
  *"Logged to Halyard:"*) exit 0 ;;
esac

TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

# Already nudged at an earlier stop this session — don't repeat.
if grep -q 'decide silently whether this session produced durable knowledge' "$TRANSCRIPT_PATH"; then
  exit 0
fi

# Outcomes captured earlier this session (under any MCP prefix) — pass
# through silently.
if grep -qE '"name":"mcp__[^"]*__(summarize_work|upsert_knowledge)"' "$TRANSCRIPT_PATH"; then
  exit 0
fi

# Only nudge when the transcript shows signs of substantive activity (edits,
# delegation, or external research). `Task` is the pre-2.1.63 name of the
# subagent tool, kept for older clients. Sessions with none of these end
# untouched.
if ! grep -qE '"name":"(Edit|Write|MultiEdit|NotebookEdit|Agent|Task|WebSearch|WebFetch)"' "$TRANSCRIPT_PATH"; then
  exit 0
fi

cat <<'JSON'
{
  "decision": "block",
  "reason": "Before finishing, decide silently whether this session produced durable knowledge: code changes with non-obvious reasoning, a decision and its rationale, debugging findings, research conclusions, or a reusable answer from the user. If it did, call mcp__plugin_halyard_org-kb__summarize_work (the same tool may be mounted as mcp__halyard__summarize_work or mcp__ask-expert__summarize_work) with the most appropriate entry_type (WORK_OUTPUT, DECISION, PROCESS, or CONTEXT), then end your turn. If it did not, end your turn immediately with no further message: do not ask the user whether to log, do not summarise the session, and do not explain why nothing was logged."
}
JSON
