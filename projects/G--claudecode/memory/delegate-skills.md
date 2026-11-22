---
name: delegate-skills
description: 額度快用完時把工作交辦給 codex/grok/agy/SSH(161,005) 的三個 skill 與實測限制
metadata:
  type: reference
---

2026-11-22 建立三個 skill（`C:\Users\capbair\.claude\skills\`）:`delegate`(入口:查額度、寫交接規格、選代理、驗收)、`delegate-local`(本機 codex/grok/agy,`run_local.ps1`)、`delegate-remote`(SSH 161/005 的 codex,`run_remote.ps1`)。共用 `delegate\rules_zh.md`、`handoff_template.md`。

**實測(2026-11-22)**:本機 codex 89s、agy 84s、grok 185s 都通過冒煙測試;codex@161 通過(140s);**codex@005 預設沙盒失敗**(SSH 下 `connecting runner pipe-in timed out`),`-Full` 關沙盒尚未驗證、需使用者同意。grok `-p` 不支援 `--add-dir`。agy CLI 預設模型是弱的 Gemini 3.8 Flash,腳本改用 gemini-4-neon-high。

**Why:** 使用者 Claude Code 5 小時額度常見用完;Fork 出去的 session 與原 session 可能同時收到「Try again」而同時動同一批檔案,所以交辦前只讓一個 session 負責。
**How to apply:** 使用者說「交辦/額度快沒了/交給 xx」時用 `delegate` skill。遠端不得開視窗、不用 schtasks(見全域 CLAUDE.md)。[[taipei-city-map-project]] 的 L1 v03 工作尚未交辦,規格也還沒寫。
