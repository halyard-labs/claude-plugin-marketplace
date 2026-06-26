---
name: triage-knowledge
description: >-
  Review and clear the knowledge base inbox — the queue of AI-generated
  candidate entries awaiting human approval before they go live. Use when the
  user asks to review the inbox, triage pending knowledge, approve or reject
  candidate entries, clear the review queue, or check what's waiting to be
  filed. Triggers on 'review the inbox', 'triage knowledge', 'what's pending
  approval', 'clear the queue', 'accept/dismiss candidates', 'review draft
  entries'. Candidates accepted here enter the live, searchable knowledge base.
---

# Triage Knowledge

Agent-authored entries (from `summarize_work`, `summarize_conversation`, and `upsert_knowledge`) don't go straight into the live knowledge base — they land in an **INBOX review queue** as candidates. This skill is the human-in-the-loop review step: accept the good ones, dismiss the noise, and tighten drafts before they're filed.

Admins see the whole org queue; non-admins see only their own candidates.

## Workflow

```
1. mcp__plugin_halyard_org-kb__list_triage(...)          → See what's waiting
2. mcp__plugin_halyard_org-kb__get_triage_item(...)      → Read a candidate in full before deciding
3. (optional) suggest_triage_edits → apply_triage_suggestion → Refine the draft
4. mcp__plugin_halyard_org-kb__accept_triage(...)        → File it into the live KB
   OR mcp__plugin_halyard_org-kb__dismiss_triage(...)    → Archive without filing
```

Always `get_triage_item` before accepting/dismissing — `list_triage` returns metadata (and snippets only if you ask), not the full draft.

## 1. List the queue

```
mcp__plugin_halyard_org-kb__list_triage()                              // your pending candidates
mcp__plugin_halyard_org-kb__list_triage(filter: "all")                 // admins: whole org queue
mcp__plugin_halyard_org-kb__list_triage(filter: "overdue", include_content: true)
```

| Parameter         | Description                                                       |
| ----------------- | ----------------------------------------------------------------- |
| `filter`          | `"all"`, `"mine"`, or `"overdue"` (non-admins are scoped to mine) |
| `include_content` | Include candidate snippets (default: false)                       |
| `limit` / `offset`| Pagination (default limit 20)                                     |

## 2. Inspect a candidate

```
mcp__plugin_halyard_org-kb__get_triage_item(triage_id: "...")
```

Returns the full draft title/content plus the review-message history. Read this before any accept/dismiss/edit.

## 3. Refine before filing (optional)

Stage an edit to a candidate's draft, review it, then apply it:

```
mcp__plugin_halyard_org-kb__suggest_triage_edits(
  triage_id: "...",
  instruction: "Tighten to 3 bullets and add the repo name to the title"
)
// review the staged title/content in the returned assistant message, then:
mcp__plugin_halyard_org-kb__apply_triage_suggestion(
  triage_id: "...",
  message_id: "...."   // the assistant message ID holding the staged draft
)
```

`suggest_triage_edits` only stages a revision — nothing changes until `apply_triage_suggestion`. You can also skip staging entirely and pass final overrides straight into `accept_triage`.

## 4. Accept or dismiss

```
// File into the live knowledge base (queues embeddings, stamps review metadata)
mcp__plugin_halyard_org-kb__accept_triage(
  triage_id: "...",
  reason: "Useful runbook, accurate",
  title: "Optional final title override",
  content: "Optional final content override",
  entry_type: "PROCESS",          // optional re-type
  tags: ["auth", "runbook"]       // optional final tags
)

// Archive without filing (keeps review metadata)
mcp__plugin_halyard_org-kb__dismiss_triage(
  triage_id: "...",
  reason: "Duplicate of ke_123 / too trivial to keep"
)
```

To remove a candidate entirely rather than archive it, use `mcp__plugin_halyard_org-kb__delete_triage_item(triage_id: "...")`.

## Tips

- **Read before you rule** — always `get_triage_item` first; `list_triage` alone isn't enough to judge.
- **Edit, don't reject, salvageable drafts** — if a candidate is right but sloppy, refine it (step 3) or pass overrides to `accept_triage` rather than dismissing and losing the work.
- **Give a reason** — `accept_triage` and `dismiss_triage` both take a `reason`; it's preserved as review metadata and helps the next reviewer.
- **Dedup against the live KB** — before accepting, a quick `search_knowledge` for the topic catches candidates that duplicate existing entries (dismiss those, or `supersedes_entry_id` if the new one is better).
- **Accepting is what makes it searchable** — until a candidate is accepted it won't surface in `search_knowledge` / `list_knowledge`.
