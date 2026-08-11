---
name: feedback-always-respond-in-chinese
description: "User corrected a lapse where prose responses drifted into English during a long code-building session, despite the global CLAUDE.md rule to always respond in Traditional Chinese"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 621fdbe0-b149-4124-b8a0-0fb96996a38e
  modified: 2026-08-11T08:54:47.405Z
---

Always respond to the user in Traditional Chinese (繁體中文), per the user's global `CLAUDE.md`
instruction — this applies to every message, including long technical/code-building sessions.

**Why:** on 2026-08-11, during an extended session building the `solis-fabric-chat` WordPress plugin
(many file writes, test runs, git operations), the assistant's prose responses drifted into English
for several turns in a row. The user had to explicitly point it out ("你不能寫中文嗎?"). The global
rule was never in question — the lapse was losing track of it while focused on code/tool output.

**How to apply:** code itself (comments, docblocks, commit messages, variable names) stays in English
per normal software convention — that's not what this rule is about. But every user-facing prose
message — status updates, summaries, questions, explanations of what was built — must be in
Traditional Chinese, even mid-session when the working content (file paths, test output, technical
terms) is heavily English. Don't let a long stretch of English-heavy tool output pull the response
language along with it. If in doubt mid-session, re-check the last few responses' language before
sending the next one.
