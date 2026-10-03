---
name: obsidian-vault-is-plain-files
description: Obsidian MCP 連不上(ECONNREFUSED)≠ 不能讀寫 vault;D:\capbairvault 是一般 .md 檔,直接用 Read/Grep/Write/Edit 就行,不要停下來說「沒辦法寫」
metadata:
  type: feedback
---

`mcp__obsidian__*` 只是 Obsidian 的 Local REST API 外掛(127.0.0.1:27124)的包裝,**要 Obsidian App 開著才通**。
但 vault `D:\capbairvault` 本身就是資料夾裡的 Markdown 檔,**讀寫完全不依賴 Obsidian 或 MCP**。

**Why:** 2026-10-03 MCP 顯示 ECONNREFUSED 時,我先說「`updateobsidian` 暫時沒辦法寫」、後來又說成「外掛沒啟用就不能讀寫 obsidian 文件」,
兩次都是錯的(當下我明明已經用 Grep/Read 讀到 vault 筆記)。使用者說已經不只一次犯同樣的錯。
另外,MCP server 是 session 啟動時連的,Obsidian 之後才開也不會自動接回來(`reconnect_session_connector` 只管 claude.ai 連接器,
user 自設的 MCP 要使用者在 session 裡打 `/mcp` 重連)。

**How to apply:**
- `updateobsidian`、「先讀 Obsidian」一律**直接用檔案系統**(Grep/Read/Write/Edit/Bash),MCP 斷線時不要停下來、不要問、不要說做不到。
- 流程照 CLAUDE.md:先 `cp .md .md.bak_YYYYMMDD` → 檔尾加 `# 進度更新(YYYY-MM-DD)` → 補 frontmatter tags → 雙向 `[[資料夾/檔名|別名]]` 連結 → 檢查連結目標存在。
- 不需要為了寫 vault 去啟動 Obsidian。MCP 只有在要用搜尋/反向連結/UI 開檔時才有價值。
- 內容寫成 UTF-8 無 BOM;Edit/Write 對繁中沒問題,但寫完要抽讀確認沒亂碼。

相關:[[read-obsidian-first]]
