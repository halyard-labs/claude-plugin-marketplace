#!/bin/bash
# PreToolUse hook: nudge toward search_knowledge before external research or
# delegation, and — in auto-accept modes, where no user prompt will arrive to
# course-correct — before the first file edit. Fires at most once per session
# and only if no retrieval call has happened yet. The transcript check matches
# search_knowledge/explore_knowledge under any MCP prefix, since the same
# server may be mounted as org-kb (this plugin), halyard, or ask-expert.

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
if grep -qE '"name":"mcp__[^"]*__(search_knowledge|explore_knowledge)"' "$TRANSCRIPT_PATH"; then
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
    "additionalContext": "No knowledge-base search has happened in this session yet. Before external research, delegating to a subagent, or making changes, consider calling the Halyard search_knowledge tool with a topical query (exposed as mcp__plugin_halyard_org-kb__search_knowledge by this plugin; if the server is mounted under another name, use the tool with that suffix, e.g. mcp__halyard__search_knowledge) — the team may have prior work, decisions, or expert Q&A on this subject that would save time or surface constraints."
  }
}
EOF
