#!/bin/bash
# SessionStart hook: orient the agent to the team knowledge base so
# search_knowledge is considered before substantive work begins.

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "This team keeps a shared knowledge base of prior work, decisions, and expert Q&A (halyard org-kb MCP). Before substantive work — research, architectural choices, debugging, or anything touching an unfamiliar system — call the Halyard search_knowledge tool with a topical query (this plugin exposes it as mcp__plugin_halyard_org-kb__search_knowledge; if the server is mounted under another name such as halyard or ask-expert, use the tool with that suffix — a different prefix does not mean the tool is unavailable); prior decisions may constrain or shortcut the approach. Follow promising hits with explore_knowledge. At the end of meaningful sessions, capture outcomes with summarize_work on the same server."
  }
}
EOF
