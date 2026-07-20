---
name: obsidian-vault-tagging-convention
description: "Default tagging and backlinking behavior when saving notes into the user's Obsidian vault"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c4e67fe3-b806-4ab1-b663-c4069785ce04
---

When writing a note into the Obsidian vault (see [[obsidian_mcp_integration]]), apply tags by default without waiting to be asked:

- 1 topic tag matching the folder the note lives in (e.g. saved into `LoRA_ComfyUI 訓練/` → `#lora`, into `網路設備維運/` → `#network`)
- 1 more specific sub-tag using Obsidian's nested tag syntax when the content warrants it (e.g. `#lora/vigor2960`, `#network/troubleshooting`)
- A `#YYYY-MM` date tag for notes where date context matters for later review (troubleshooting logs, trading/investment notes)

**Workflow**: before actually writing the file, state the proposed tags in the same message (e.g. "準備存入 `#lora/comfyui` `#2026-07`，可以嗎？") and proceed with the write unless the user corrects them in that turn. Don't open a separate confirmation round — this is meant to add visibility without adding friction. User confirmed this exact workflow on 2026-07-13.

Why: user wants tags applied consistently (for future Dataview queries) without having to remind me every time, but also wants a lightweight chance to override before the write actually happens.

**Backlinks**: when writing a note, also proactively add `[[wiki-links]]` at points that reference another topic/character/project already in the vault (or one that clearly deserves its own note), without waiting to be asked — confirmed by user 2026-07-13. If the referenced note doesn't exist yet, either create a short stub note so the link resolves, or ask the user whether to create one, depending on how substantial the missing note would be.

Related vault folder structure (created 2026-07-13, based on reviewing past session topics): `LoRA_ComfyUI 訓練/`, `3D_VR 製作/`, `網路設備維運/`, `股票投資筆記/`, `政治漫畫/`, `短影音製作/` — each seeded with a README.md. These folders/tags can be renamed or restructured freely later via `vault_move`.
