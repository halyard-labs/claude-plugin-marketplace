#!/bin/bash
# PreToolUse hook: nudge toward search_knowledge before external research
# if no retrieval call has happened in this session yet.

INPUT=$(cat)
TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

# No transcript available — pass through silently
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

# Already searched or explored this session — pass through silently
if grep -qE 'mcp__plugin_halyard_ask-expert__(search_knowledge|explore_knowledge)' "$TRANSCRIPT_PATH"; then
  exit 0
fi

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "No search_knowledge or explore_knowledge call has happened in this session yet. Before external research or delegating to a research subagent, consider calling mcp__plugin_halyard_ask-expert__search_knowledge with a topical query — the team may have prior work, decisions, or expert Q&A on this subject that would save time or surface constraints."
  }
}
EOF
