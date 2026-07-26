---
name: source-data-locations
description: "Where raw vs. curated Solis company reference material (logos, certs, product data) lives on disk"
metadata: 
  node_type: memory
  type: reference
  originSessionId: ecbf5e18-997e-4be8-bc69-00de39bf5803
  modified: 2026-07-26T07:13:42.665Z
---

- **Raw/full dump** (everything the company handed over, ~1.2GB, uncurated): `G:\claudecode\SolisWebsiteData\source`. The user moved this out of the project folder on 2026-07-23 specifically so it wouldn't need to go into git.
- **Curated subset actually useful for the website** (~143MB): `G:\claudecode\Solis Website\source`. Copied from the raw dump on 2026-07-23. This path is in the project's `.gitignore` — treat it as local-only reference material, never expect it in git history.
- Deliberately **not** copied into the curated subset (only in the raw dump, skip unless specifically asked): `包包部門文件翻譯` (unrelated bag-business line), `訂單本整理` and `2026.4.2. 單價確認通知` (internal order/pricing docs, not for publication), the top-level `Rudolf` and `BLUESIGN` folders (internal chemical-supplier audit paperwork — the actual BLUESIGN certificate PDFs are already under `source/證書/BLUESIGN`), and the rest of `五分鐘簡報` beyond the two "官網圖" folders and the AW26 exhibition folder.

**How to apply:** when doing content/design work for this project, pull assets from the curated `Solis Website\source` path first. Only reach into `SolisWebsiteData` if something specific is missing from the curated copy. See [[new-solis-website-content-status]] for what's inside and what's still missing. See [[brand-decisions]] for the logo files specifically.
