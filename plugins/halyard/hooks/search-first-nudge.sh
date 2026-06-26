#!/bin/bash
# PreToolUse hook: nudge toward search_knowledge before external research or
# delegation, and — in auto-accept modes, where no user prompt will arrive to
# course-correct — before the first file edit. Fires at most once per session
# and only if no retrieval call has happened yet.

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
PERMISSION_MODE=$(printf '%s' "$INPUT" | jq -r '.permission_mode // empty' 2>/dev/null)
TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

# No transcript available — pass through silently
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

case "$TOOL_NAME" in
  Task|WebSearch|WebFetch) ;;
  Edit|Write|MultiEdit|NotebookEdit)
    # Edits only trigger the nudge when running unattended
    case "$PERMISSION_MODE" in
      acceptEdits|bypassPermissions) ;;
      *) exit 0 ;;
    esac
    ;;
  *) exit 0 ;;
esac

# Already searched or explored this session — pass through silently
if grep -qE '"name":"[^"]*organisaton-kb__(search_knowledge|explore_knowledge)"' "$TRANSCRIPT_PATH"; then
  exit 0
fi

# Already nudged this session — don't repeat
if grep -q 'No knowledge-base search has happened in this session yet' "$TRANSCRIPT_PATH"; then
  exit 0
fi

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "No knowledge-base search has happened in this session yet. Before external research, delegating to a subagent, or making changes, consider calling mcp__plugin_halyard_organisaton-kb__search_knowledge with a topical query — the team may have prior work, decisions, or expert Q&A on this subject that would save time or surface constraints."
  }
}
EOF
