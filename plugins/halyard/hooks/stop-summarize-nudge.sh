#!/bin/bash
# Stop hook: one-time, optional nudge to capture session outcomes with
# summarize_work. Resumes the agent once with a suggestion it is free to
# ignore; fires at most once per session (stop_hook_active guard plus a
# transcript check for the nudge text, so declining it doesn't re-trigger
# at later stops) and stays silent on any error or for sessions with no
# sign of substantive work.

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)

# Already continuing because of this hook — let the session end.
ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$ACTIVE" = "true" ]; then
  exit 0
fi

TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

# Already nudged at an earlier stop this session — don't repeat.
if grep -q 'Optional, before finishing:' "$TRANSCRIPT_PATH"; then
  exit 0
fi

# Outcomes already captured this session (under any MCP prefix) — pass
# through silently.
if grep -qE '"name":"mcp__[^"]*__(summarize_work|upsert_knowledge)"' "$TRANSCRIPT_PATH"; then
  exit 0
fi

# Only nudge when the transcript shows signs of substantive work (edits,
# delegation, or external research). Trivial Q&A sessions end untouched.
if ! grep -qE '"name":"(Edit|Write|MultiEdit|NotebookEdit|Task|WebSearch|WebFetch)"' "$TRANSCRIPT_PATH"; then
  exit 0
fi

cat <<'EOF'
{
  "decision": "block",
  "reason": "Optional, before finishing: if this session produced meaningful work or durable knowledge (code changes, decisions, debugging findings, research, or reusable answers from the user), capture it with the Halyard summarize_work tool (mcp__plugin_halyard_org-kb__summarize_work in this plugin; match on the summarize_work suffix if the server is mounted under another name) using the most appropriate entry_type (DECISION, PROCESS, or CONTEXT). If the session was trivial or there is nothing worth capturing, simply finish — no call is required."
}
EOF
