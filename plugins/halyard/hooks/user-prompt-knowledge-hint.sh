#!/bin/bash
# UserPromptSubmit hook: inject a small, passive hint that durable knowledge
# in the prompt can be captured. Never blocks, never evaluates the prompt —
# the model decides relevance itself. The real capture nudge lives in the
# Stop hook; this only keeps the option present mid-session.

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Hint (ignore if not relevant): if this prompt contains durable, reusable knowledge — a decision, requirement, process, or context that would help a future session — it can be captured with mcp__plugin_halyard_org-kb__summarize_work (or mcp__plugin_halyard_org-kb__upsert_knowledge for a direct entry or a correction to an existing one; mcp__plugin_halyard_org-kb__summarize_conversation after a teammate answers a question). mcp__plugin_halyard_org-kb__search_knowledge may surface prior work on the topic."
  }
}
EOF
