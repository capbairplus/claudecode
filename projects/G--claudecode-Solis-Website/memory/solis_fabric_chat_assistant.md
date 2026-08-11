---
name: solis-fabric-chat-assistant
description: "Solis chatbot: brainstormed and built 2026-08-11 as wordpress/plugins/solis-fabric-chat — rule-book + self-hosted Ollama fallback; NOT deployed; a separate, superseded design exists on an unmerged feature/solis-ai-robot branch"
metadata: 
  node_type: memory
  type: project
  originSessionId: 621fdbe0-b149-4124-b8a0-0fb96996a38e
  modified: 2026-08-11T09:09:03.724Z
---

## What was decided and built (2026-08-11)

Brainstormed with the user in 5 steps, then wrote a spec and built it the same session:
- **Purpose:** fabric/product query assistant, routes commercial questions to the existing
  `solis-inquiry` form (not a general FAQ bot, not lead-qualification-first).
- **Architecture:** rule book first (fixed FAQ + taxonomy-filter matching, zero AI cost), Ollama
  fallback only when the rule book finds nothing.
- **AI provider:** self-hosted Ollama at `http://192.168.1.161:11434` (chavi's machine — same host
  `solis-news-aggregator`'s `OllamaAnalyzer` already uses), model `deepseek-r1:7b`. No cloud API,
  no per-token cost, no concurrency limiting in v1 (ship first, add a limiter if real traffic needs it).
- **Data scope:** answers reflect current live gating — reuses
  `Solis\Member\Visibility\FabricAccessGate` so a chat reply never shows more than the same visitor
  already sees on the site (see corrected [[registered-member-portal-scope]]: the gate is live, not
  reserved). MOQ/lead-time/price are never answerable — the rule book always deflects those to the
  inquiry form, by construction (those fields aren't even in the Fabric REST projection).
- **Routing:** every fabric mentioned gets a "View Fabric" permalink and a "Request This Fabric"
  inquiry link, auto-carrying the visitor's last message as a prefill (`?fabric=CODE&message=...`).
- **Frontend:** site-wide floating bubble widget, zh/en toggle, plugin-owned assets (no theme edits).

**Full spec:** `new soliswebsite/Solis Fabric Chat Assistant Design.md` in Obsidian (this repo's
`new soliswebsite/` folder doubles as the Obsidian vault for this project).

**Code:** `wordpress/plugins/solis-fabric-chat/` — `FaqRuleBook`, `FilterIntentParser`,
`FabricFilterQuery`/`FabricRepository`, `OllamaChatClient`, `ChatOrchestrator` (built against
`Contracts\FabricSearcher`/`ChatCompletionClient` interfaces so it's unit-testable with fakes),
`ChatRestController` (`POST /wp-json/solis-chat/v1/message`), `assets/js/widget.js`+`widget.css`.
Also touched `solis-inquiry`'s `AbstractInquiryForm::render()` to add a `message` GET-param prefill
(new, alongside the pre-existing `fabric` param prefill).

**Verified as of 2026-08-11:** all PHP lints clean, 22 new PHPUnit tests pass, existing
`solis-inquiry` suite (18 tests) still passes after the edit, `widget.js` parses clean under Node.

**Deployed 2026-08-11** (user approved after reconnaissance) to `C:\solistex-new\wp-content\plugins\solis-fabric-chat` on `192.168.1.7` via scp, activated via wp-cli, active alongside `solis-member`/`solis-inquiry` (also already live there). All three response branches verified live via curl against `http://192.168.1.7:8082/wp-json/solis-chat/v1/message`: FAQ rule-book match, taxonomy-filter fabric match (with correct per-fabric gating — one seed fabric has `visibility_level=Public` so its specs show), and Ollama fallback (model resolved to real product codes, re-fetched from WordPress rather than trusted from the LLM). Homepage still 200s; widget CSS/JS/root div confirmed present in page source.

**Real bug found and fixed during live verification:** `InquiryLinkBuilder` passed raw message text into WordPress's `add_query_arg()`, which — unlike the test stub's PHP-native `http_build_query()` — does **not** urlencode values. A message ending in `?` truncated the query string live (`?message=What is your MOQ` — missing the `?`). Fixed by `rawurlencode()`-ing every value before `add_query_arg()`, and corrected the test stub in `tests/php/wp-stubs.php` to match real WP behavior (no auto-encoding) so this class of bug is caught locally next time. **Lesson:** `add_query_arg()`/`add_query_arg`-family WP stubs must not silently urlencode when the real function doesn't — a stub that's "more correct" than the real API hides real bugs.

Browser-pane visual screenshot of the widget was attempted but blocked — the Claude Browser tool
refuses per-action approval for the internal `192.168.1.7` host, so visual confirmation relies on curl
output + page-source checks, not a screenshot. If visual confirmation matters later, open it in a
real browser by hand.

Ollama model note: no `deepseek-r1:7b` tag exists on the host — using `deepseek-r1:latest` (~8B)
instead, confirmed live via `/api/tags`.

## The other chatbot design — don't confuse the two

A **separate, earlier** design exists on an **unmerged branch/worktree**:
`feature/solis-ai-robot`, worktree at `.worktrees/solis-ai-robot`, 2026-07-21, built via Codex CLI
(not Claude Code). Plan: `docs/superpowers/plans/2026-07-21-solis-ai-robot.md`. Spec:
`docs/superpowers/specs/2026-07-21-solis-ai-robot-design.md`. Progress: 2 of 8 tasks done (plugin
skeleton + OpenAI structured-extraction adapter, commit `0a66c67`).

That design is **fundamentally different**, not a version of the same thing:
- OpenAI Responses API (`gpt-5.6-sol`), not self-hosted Ollama.
- English-only v1, explicitly excludes other languages — vs. this design's zh/en from v1.
- Its own `solis_ai_lead` CPT + email notification — vs. this design reusing `solis-inquiry`'s
  existing `inquiry` CPT.
- LLM-first structured extraction + deterministic weighted matcher — vs. this design's rule-book-first,
  LLM-only-as-fallback split.

**User's explicit decision (2026-08-11):** proceed with the new/current design; the
`feature/solis-ai-robot` branch is kept as unmerged reference, not continued, not merged.

**How to apply:** if the chatbot comes up again, this memory + the design doc are the current state.
Don't rediscover `feature/solis-ai-robot` as if it were live work in progress — it's parked. Don't
assume `solis-fabric-chat` is deployed just because the code exists — check `192.168.1.7` directly
(SSH, per [[solis-infrastructure-topology]]) before claiming it's live, per
[[check-before-claiming-not-done]].
