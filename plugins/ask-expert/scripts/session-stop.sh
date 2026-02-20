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

# Block the stop and give Claude the choice to summarize or skip
jq -n '{
  "decision": "block",
  "reason": "Before ending, consider whether this session involved meaningful work worth logging (e.g., code changes, architectural decisions, debugging insights, or non-trivial research). If so, call mcp__ask-expert__summarize_work with a clear title, concise summary, and relevant tags. If the session was trivial (a quick question, simple lookup, or minor clarification), skip summarizing and stop immediately."
}'
