#!/bin/bash
# SessionStart hook: orient the agent to the team knowledge base so
# search_knowledge is considered before substantive work begins.

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "This team keeps a shared knowledge base of prior work, decisions, and expert Q&A (halyard org-kb MCP). Before substantive work — research, architectural choices, debugging, or anything touching an unfamiliar system — call mcp__plugin_halyard_org-kb__search_knowledge with a topical query; prior decisions may constrain or shortcut the approach. Follow promising hits with explore_knowledge. At the end of meaningful sessions, capture outcomes with mcp__plugin_halyard_org-kb__summarize_work."
  }
}
EOF
