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

A **definitional term** is org/product/industry jargon whose meaning isn't obvious from the words — a coined concept ("the loop"), a product surface ("triage inbox"), an acronym, or a term used with a precise in-house meaning. Marking a term links it to its canonical `DEFINITION` entry so readers (human and agent) can resolve it and the knowledge graph gains a real edge instead of a bare string.

## When to mark

Mark a term when **all** of these hold:

- It's **load-bearing** — the entry's meaning depends on the reader knowing it.
- It's **non-obvious** — a new hire or fresh agent couldn't infer it from context.
- It **recurs** — the org uses it across conversations, not a one-off phrase.

Skip common English, self-evident words, and terms already defined earlier in the same entry (mark first use only).

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
- Don't force it. A definition that only restates the term, or jargon nobody else uses, is noise — leave it unmarked.
