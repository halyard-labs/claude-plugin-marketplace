---
name: ask-for-help
description: >-
  Send questions to human experts via Slack when you encounter ambiguity,
  need decisions, or require information not in the codebase. ALWAYS
  summarize helpful answers to build organizational knowledge.
---

# Ask for Help

Use the ask-expert MCP tools to get human input when you're blocked, need clarification, or face decisions that require human judgment. **ALWAYS summarize helpful answers** to build a knowledge base.

## Complete Workflow

Every interaction should follow this pattern:

```
1. list_experts()          → Find the right expert
2. ask_expert(...)         → Send your question (returns immediately)
3. check_response(...)     → REQUIRED: Wait for the response
4. summarize_conversation  → CRITICAL: Capture what you learned
   OR close_conversation   → (with summary parameter)
```

**Steps 3 and 4 are critical**—`ask_expert` returns immediately after notifying the expert, so you MUST call `check_response` to get their reply. Without summarization, the knowledge is lost and experts get asked the same questions repeatedly.

## When to Ask for Help

Ask for help when:

- **Ambiguous requirements** — The task description is unclear or could be interpreted multiple ways
- **Design decisions** — Multiple valid approaches exist and you need guidance on which to choose
- **Domain expertise needed** — The task requires knowledge you don't have (e.g., business logic, design preferences)
- **Blocked by external factors** — You need credentials, access, or information only a human can provide
- **Verification needed** — You want to confirm an approach before investing significant effort

Do not ask for help when:

- You can find the answer by reading code or documentation
- The task is straightforward and well-defined
- You're just uncertain—try first, then ask if truly stuck

## Available Tools

### 1. List Available Experts

Before asking, check who's available:

```
mcp__ask-expert__list_experts()
mcp__ask-expert__list_experts(role: "designer")
mcp__ask-expert__list_experts(skill: "security")
mcp__ask-expert__list_experts(available_only: true)
```

### 2. Ask an Expert

Send a question to an expert by role or skill:

```
mcp__ask-expert__ask_expert(
  prompt: "Your question here",
  role: "designer"  // or use skill: "ui-design"
)
```

**Parameters:**

| Parameter | Description                                                     |
| --------- | --------------------------------------------------------------- |
| `prompt`  | The question or request (required)                              |
| `role`    | Expert role: "designer", "architect", "pm", "engineer"          |
| `skill`   | Expert skill: "ui-design", "security", "database", "typescript" |
| `options` | Optional array of choices for the expert to pick from           |

**With options** (when you want a specific choice):

```
mcp__ask-expert__ask_expert(
  prompt: "Should we use server-side or client-side validation for this form?",
  role: "architect",
  options: [
    { label: "Server-side only", value: "server" },
    { label: "Client-side only", value: "client" },
    { label: "Both", value: "both" }
  ]
)
```

### 3. Check for Response (Required)

`ask_expert` returns immediately after notifying the expert. You MUST call `check_response` to wait for their reply:

```
mcp__ask-expert__check_response(
  conversation_id: "conversation-id-from-ask-expert",
  wait: true  // Wait up to 55 seconds for response
)
```

If no response yet, call again to continue waiting.

### 4. Summarize What You Learned (CRITICAL)

**Always call this after receiving a helpful response.** This builds organizational knowledge so experts don't get asked the same questions repeatedly.

```
mcp__ask-expert__summarize_conversation(
  conversation_id: "conversation-id",
  question: "Should we use JWT or session auth for the mobile app? Our existing mobile SDK expects Bearer tokens.",
  answer: "Use JWT with refresh tokens because mobile clients need stateless auth and we already have JWT infrastructure in the API."
)
```

**Parameters:**

| Parameter         | Description                                                  |
| ----------------- | ------------------------------------------------------------ |
| `conversation_id` | The conversation ID from ask_expert (required)               |
| `question`        | The question or context that was asked (required)            |
| `answer`          | The answer, decision, or guidance from the expert (required) |

**Write effective summaries:**

- **question**: Write it so someone with a similar question would recognize it as relevant
- **answer**: Include key reasoning and context that makes the answer useful

### 5. Search Knowledge Base

Search the knowledge base for answers from previous expert conversations **and** work summaries from past sessions. This is useful for finding information about what was discussed, decided, or built in earlier conversations — so always check here before asking an expert.

```
mcp__ask-expert__search_knowledge(
  query: "how do we handle authentication?"
)
```

Use this to:

- **Find answers to questions that were already asked** — avoid repeating questions experts have already answered
- **Look up work done in previous sessions** — summaries logged via `summarize_work` are searchable here
- **Discover past decisions and context** — understand why something was built a certain way

### 6. Save Work Summaries

After completing significant work, save a summary for future reference. These summaries are searchable via `search_knowledge`, making it easy for future sessions to understand what was done and why.

**Note:** A session stop hook is configured to remind you to call this before ending a session, so work is always logged.

```
mcp__ask-expert__summarize_work(
  title: "Implemented user authentication",
  summary: "Added JWT-based auth with refresh tokens...",
  tags: ["authentication", "security", "backend"]
)
```

### 7. Close Conversation (Without Summary)

Close a conversation without capturing knowledge (not recommended):

```
mcp__ask-expert__close_conversation(
  conversation_id: "conversation-id"
)
```

**Note:** Prefer using `summarize_conversation` instead, which both captures knowledge and closes the conversation.

## Writing Good Questions

**Be specific and provide context:**

```
# Bad
"How should I do authentication?"

# Good
"We're adding user authentication to the API. The app uses Fastify
and Prisma. Should we use JWT tokens with refresh tokens, or
session-based auth with cookies? The app will have both web and
mobile clients."
```

**Include what you've already considered:**

```
"I need to add file upload to the form. I'm considering:
1. Direct upload to S3 with presigned URLs
2. Upload through our API server

The files are user avatars (small images). Which approach
fits our architecture better?"
```

**State the decision you need:**

```
"The sidebar component can either use CSS transitions or
Framer Motion for animations. Our existing components use
both patterns. Which should I use for consistency?"
```

## Complete Workflow Example

```
// 1. Find an expert
mcp__ask-expert__list_experts(skill: "ui-design")

// 2. Ask your question (returns immediately)
mcp__ask-expert__ask_expert(
  prompt: "The design shows cards with hover states. Should I use
           CSS transitions or Framer Motion? We use both in the codebase.",
  skill: "ui-design"
)
// Returns immediately: { status: "pending", conversation_id: "conv_abc123" }

// 3. Wait for response (REQUIRED - ask_expert doesn't wait)
mcp__ask-expert__check_response(
  conversation_id: "conv_abc123",
  wait: true
)
// Expert responds: "Use CSS transitions for simple hover states.
//    Framer Motion is for complex animations like page transitions."

// 4. ALWAYS summarize the knowledge gained
mcp__ask-expert__summarize_conversation(
  conversation_id: "conv_abc123",
  question: "CSS transitions vs Framer Motion for card hover states?",
  answer: "Use CSS transitions for simple hover effects. Framer Motion should be reserved for complex animations like page transitions and multi-step sequences. Guideline: Simple state changes = CSS, complex/sequenced animations = Framer Motion."
)
```

## Tips

- **Search first** — Use `search_knowledge` before asking an expert; answers from past conversations and work summaries from previous sessions are all searchable
- **Be patient** — Experts are notified via Slack and may not respond immediately
- **Continue other work** — While waiting, work on unblocked tasks
- **One question at a time** — Keep questions focused; ask follow-ups separately
- **Provide options when possible** — Makes it easier for experts to respond quickly
- **ALWAYS summarize** — This is the most important step for building organizational knowledge
- **Work gets logged automatically** — A session stop hook will prompt you to call `summarize_work` before ending, ensuring nothing is lost
