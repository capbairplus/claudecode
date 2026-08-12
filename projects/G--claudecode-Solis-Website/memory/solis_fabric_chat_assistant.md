---
name: solis-fabric-chat-assistant
description: "Solis chatbot (wordpress/plugins/solis-fabric-chat): rule-book + self-hosted Ollama fallback, deployed live 2026-08-11; LINE bot channel added 2026-08-12 but blocked on a public HTTPS webhook URL; a separate superseded design sits on the unmerged feature/solis-ai-robot branch"
metadata: 
  node_type: memory
  type: project
  originSessionId: 621fdbe0-b149-4124-b8a0-0fb96996a38e
  modified: 2026-08-11T17:03:09.999Z
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

## Follow-up fixes from live user testing (2026-08-11, same day)

The user actually clicked around the deployed widget and found two real issues:
1. **No loading feedback** — a correct ~18s Ollama-fallback response looked identical to a hang.
   Fixed: `OllamaChatClient` now sends `"think": false` (deepseek-r1 skips its chain-of-thought
   trace — cut a trivial prompt from ~18s to ~1.4–4s) + `num_predict: 400`; widget now shows an
   animated 3-dot typing indicator, disables Send while waiting, and supports Ctrl/Cmd+Enter to
   submit with a persistent hint line (not just placeholder text, which disappears once the user
   types). Version bumped 0.1.0 → 0.1.2 across these fixes for cache-busting, each redeployed and
   reverified live.
2. **Ollama host contention is a real, already-observed risk, not hypothetical.** Mid-session, even
   a trivial "say hi" (`num_predict: 10`, `think: false`) to `192.168.1.161:11434` timed out at 30s
   and then 20s on retry, while `/api/tags` (lightweight metadata) responded in ~15ms both times —
   the Ollama *server* is up, but *inference* is blocked/queued behind something else (consistent
   with [[CLAUDE.md]]'s note that this machine also does other GPU work, e.g. LoRA training, and
   isn't dedicated to Ollama). Response: bumped `OllamaChatClient`'s `wp_remote_post` timeout
   30s → 45s for more grace, but this is fundamentally a shared-resource capacity risk, not something
   fixable purely in `solis-fabric-chat`'s code. The FAQ and taxonomy-filter branches are unaffected
   (they never call Ollama at all) — only the open-ended LLM-fallback branch degrades to the
   "temporarily unavailable" message when the host is this busy, which is the designed fallback
   behavior working correctly, not a crash.

**How to apply:** if the chatbot's LLM-fallback branch seems slow or reports "unavailable" again,
check `curl http://192.168.1.161:11434/api/tags` (should be near-instant) vs. an actual `/api/chat`
call before assuming a code bug — it may just be that machine busy with unrelated work again. If this
becomes a recurring problem, consider a request queue/concurrency limit (explicitly deferred in the
original design decision — "ship first, add if traffic shows a real problem") or a second Ollama
host.

## LINE channel added (2026-08-12)

User asked to make the same assistant reply through a LINE bot. Built as a **second front end onto
the same `ChatOrchestrator`**, not a second bot: `src/Line/` (`LineChannelConfig`,
`LineSignatureVerifier`, `LineLocale`, `LineMessageBuilder`, `LineMessagingClient`) +
`Rest/LineWebhookController` (`POST /wp-json/solis-chat/v1/line/webhook`). Plugin 0.1.2 → 0.2.0.
Suite now 39 tests / 81 assertions green, lints clean.

Design choices worth remembering:
- Credentials are wp-config constants (`SOLIS_LINE_CHANNEL_SECRET`, `SOLIS_LINE_CHANNEL_ACCESS_TOKEN`),
  matching `SOLIS_OLLAMA_URL`; the webhook route is **only registered when both are set**, so an
  unconfigured site can't expose an unauthenticated endpoint.
- Auth is the `X-Line-Signature` HMAC only (no WP nonce — LINE posts from the public internet), and
  an empty secret fails closed.
- Locale comes from the message text (Han character → zh), because LINE has no zh/en toggle.
- Gating is safe by construction: a LINE user is never a logged-in WP user, so `FabricAccessGate`
  gives public-only fields.

**NOT deployed, NOT verified live as of 2026-08-12.** The blocker is infrastructure, not code: LINE's
servers must reach the webhook over **public HTTPS with a valid certificate**, and the install
currently answers only on `http://192.168.1.7:8082` (LAN) — see [[solis-infrastructure-topology]].
Every link inside a reply (permalink, inquiry URL, hero image) must likewise be a public URL, so
`home_url()` has to be the public HTTPS origin; http:// hero images are dropped outright because
LINE requires HTTPS for images. Also needs "Auto-reply messages" turned off in the LINE Official
Account Manager, or the canned reply fires alongside the bot's answer.

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
