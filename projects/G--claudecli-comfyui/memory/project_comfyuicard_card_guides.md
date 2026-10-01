---
name: project-comfyuicard-card-guides
description: "Per-card \"使用說明\" (usage guide) feature added to comfyuicard on 2026-09-30 — how it's generated and where it lives"
metadata: 
  node_type: memory
  type: project
  originSessionId: 34985248-288c-4572-8ef9-f78b30d96a47
  modified: 2026-09-30T15:36:32.662Z
---

Added a "📖 使用說明" (usage guide) feature to `comfyuicard` reachable from every card: a small icon on each card tile in `index.html` (next to the pin star) and a button in `card.html`'s header, both opening the same shared bottom-sheet component (`wfuiOpenSheet`).

**Key design decision**: the guide content is **auto-generated from the card's own manifest.json** (`wfuiBuildGuideHtml(manifest)` in `wwwroot/app.js`), not hand-authored per card. It renders: title, description, category, and every field's label/type/required-vs-optional/options list/default value/`help_text` — all pulled directly from data that was already there. This was a deliberate choice over writing 109 individual guide documents: it can never go stale (manifest changes → guide changes automatically), it required zero backend changes (the full manifest, including `fields[]`, was already being fetched client-side via the existing `loadCard(id)` → `GET api/cards/{id}`), and it's honest — it surfaces real already-authored `help_text` rather than fabricating per-card advice from scratch. Cards with especially rich `help_text` (e.g. `txt2img_qwen21` — GGUF model tradeoffs, VRAM guidance, timing data) produce genuinely detailed guides; cards with sparse manifests get a thinner but still accurate one.

The pre-existing hand-authored guide (`guide-qwen-image-21.html`, linked via a special banner for the 6 Qwen-Image 2.1 family cards) still exists separately and coexists fine with the new generic button — the two aren't mutually exclusive.

**Scope limitation on index.html**: the guide icon only appears on tiles that map straight to `card.html?id=...` (a `guideId` set in `cardEntry()`) — grouped tiles (`card.html?group=...`, e.g. the minimax_h3 family) and tiles that route to their own dedicated page (Storyboard Canvas/Director, Manga Canvas, Cinema/NSFW Prompt) don't get one in the browse grid, since there's no single manifest to summarize there. Once inside `card.html` for a specific variant, the guide button always shows.

Verified: 122-page puppeteer sweep at 375px after this change — 0 overflow, 0 JS errors. Screenshotted both entry points with real manifest data (Florence-2 Caption from the index tile, txt2img_qwen21 from card.html) confirming genuinely useful, correctly-escaped content renders.

This work happened in `C:\wordpresscb\workflowui-csharp-poc` (same session as [[project_comfyuicard_relocation]]) and was re-synced into `D:\myproject\ComfyuiCard` afterward via the same `robocopy /XD bin obj /XF appsettings.json restart_service.bat CLAUDE.md svc_id_ed25519_161` pattern — the exclude list matters: those four files were already hand-customized for the new location and would be clobbered by a naive re-sync.
