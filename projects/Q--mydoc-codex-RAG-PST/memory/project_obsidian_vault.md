---
name: project-obsidian-vault
description: "RAG-PST project has a companion Obsidian vault at D:\\capbairvault with a note that predates and mirrors the repo's project-history doc"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 43f4933d-a028-41d2-8c7b-ac38a29d27ef
  modified: 2026-08-12T14:26:47.474Z
---

The user keeps an Obsidian vault at `D:\capbairvault` on their workstation (the machine Claude Code runs on, not the chavi 192.168.1.161 machine). This project's note lives at `D:\capbairvault\RAG\PST\PST RAG project-history-and-roadmap.md`.

**Why this matters:** This vault note is the *original* clean-Chinese source that the repo's `docs/project-history-and-roadmap.md` was meant to mirror — comparing the two on 2026-08-12 proved the repo copy had been mojibake-corrupted at some point after an early sync, while the vault original stayed readable. The vault note was very stale (last substantively updated ~2026-07-26, describing Phase II as still "in progress" when Task 1–12 were actually all done by 2026-08-12) until it was brought current on 2026-08-12.

Other project-relevant vault notes found under `D:\capbairvault\Codex\`: `2026-07-24 Outlook PST RAG 週用量異常檢討.md` (an early incident review — flagged wasteful ~30s polling loops and building large Python venvs on a network drive, `G:\` — the same network-drive-venv corruption pattern recurred again on 2026-08-12 with `Q:\`/`D:\mydoc\codex\RAG-PST\.venv`). `2026-08-01 Solis RAG 對話總結.md` is a *different*, unrelated "Solis RAG" project — don't confuse the two.

**How to apply:** When asked to write/update project documentation for RAG-PST, ask (or check) whether it should go to the repo's `docs/`, this Obsidian vault path, or both — the user has asked for both at different times. If updating the vault note, preserve its existing Obsidian conventions (frontmatter tags, `[[wiki-links]]`, 反向連結 backlink lists, the "文件維護規則" section it defines for itself).
