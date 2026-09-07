---
name: mark-terms
description: >-
  Mark definitional terms when authoring knowledge — link org/product/industry
  jargon to its canonical DEFINITION entry so the graph connects. Use when
  writing or updating a knowledge entry (summarize_work, summarize_conversation,
  upsert_knowledge) and the text leans on a named concept, product surface,
  acronym, or coined phrase a newcomer or agent wouldn't already know. Triggers
  on 'what does X mean', 'define this term', 'add a glossary entry', 'link the
  term', or first use of load-bearing jargon in an entry you're writing.
---

# Mark Terms

> **Tool names.** The default names below are the halyard plugin's `org-kb` server as Claude Code exposes it: `mcp__plugin_halyard_org-kb__<tool>`. Older connections expose the same server under other prefixes — `mcp__halyard__<tool>` (standalone server added by the docs or `halyard setup`) and `mcp__ask-expert__<tool>` (claude.ai connector, Claude Code on the web) — and Codex and Cursor derive their own prefix from the `org-kb` key. These are aliases for one server, so match on the part after the last `__`: if the default name is not in your tool list, use whichever alias is present (search the deferred tool list for the bare name if needed) rather than concluding the tool is unavailable.

A **definitional term** is one that carries **specific significance to the company** — a name or word this org gives a meaning it wouldn't have to an outsider. That's the whole bar. Two kinds qualify:

- **Coined / unique to the company** — a concept, product surface, project, or acronym this org invented ("the loop", "triage inbox", an internal codename).
- **A common word used with a precise in-house meaning** — an everyday term the company loads with a specific definition that differs from, or narrows, the generic one.

Marking links the term to its canonical `DEFINITION` entry so readers (human and agent) resolve it the same way, and the knowledge graph gains a real edge instead of a bare string.

## When to mark

Mark a term when **all** of these hold:

- It's **company-specific** — coined here, or a common word this org uses with a particular meaning. This is the gate; if the term means the same thing everywhere, it does not belong here.
- It's **load-bearing** — the entry's meaning depends on the reader knowing it.
- It **recurs** — the org uses it across conversations, not a one-off phrase.

Skip common English, self-evident words, and **standard industry terms that already have a well-known public definition** (e.g. "OAuth", "webhook", "pull request") — those aren't unique to the company, so an org definition just adds noise. Also skip terms already defined earlier in the same entry (mark first use only).

## How to mark

1. **Search for an existing definition** before writing anything new:
   ```
   mcp__plugin_halyard_org-kb__search_knowledge(query: "the term", type: "DEFINITION")
   ```

2. **It exists → link first use** to its entry ID inside the entry body:
   ```
   [the loop](halyard://knowledge/ke_abc123)
   ```
   The API parses `halyard://knowledge/<id>` links out of `content` and reconciles the `REFERENCES` relation automatically — no extra call.

3. **It doesn't exist but the term is worth defining → create it**, then link to the new ID:
   ```
   mcp__plugin_halyard_org-kb__upsert_knowledge(
     title: "The loop",
     content: "The search → ask → capture cycle every knowledge interaction follows...",
     entry_type: "DEFINITION"
   )
   ```
   Keep definitions **one concept, one entry** — a tight paragraph, not a doc. New DEFINITION entries land in the triage inbox for human review before going live.

## Notes

- One canonical entry per term. If you find duplicates, link the best and flag the rest for `triage-knowledge` (`supersedes_entry_id` when one clearly replaces another).
- Don't force it. A definition that only restates the term, a generic term with a standard public meaning, or a one-off phrase nobody else reuses is noise — leave it unmarked. When in doubt, ask: *would this word mean something different inside this company than outside it?* If no, skip.
