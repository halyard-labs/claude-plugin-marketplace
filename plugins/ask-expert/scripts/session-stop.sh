#!/bin/bash
#
# Session stop hook for the ask-expert plugin.
# Prompts Claude to call summarize_work before ending a session,
# so that work done is logged and searchable in the knowledge base.
#

INPUT=$(cat)

# If the hook has already fired once this stop cycle, let Claude stop.
# This prevents an infinite loop of block → summarize → stop → block.
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Block the stop and instruct Claude to summarize its work
jq -n '{
  "decision": "block",
  "reason": "Before ending this session, please call mcp__ask-expert__summarize_work to log a summary of the work you did. Include a clear title, a concise summary of what was accomplished (and any decisions made), and relevant tags. This makes your work searchable via search_knowledge for future sessions. After calling summarize_work, you may stop."
}'
