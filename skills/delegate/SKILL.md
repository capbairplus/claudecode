---
name: delegate
description: >-
  Claude Code 額度快用完（或使用者說「交辦」「交給 codex/grok/antigravity/agy/161/005」「額度快沒了」「/delegate」）時,
  把長工作轉給其他 AI 代理執行,並把 Claude 自己的用量壓到最低:先查額度 → 寫交接規格 → 交給
  delegate-local（本機 codex / grok / agy）或 delegate-remote（SSH 到 161 / 005 的 codex）→ 只讀報告前 10 行 → 驗收。
  這是入口 skill,負責「判斷與寫規格」;實際啟動看 delegate-local / delegate-remote。
---

# delegate:額度快用完時,把工作交辦給其他 AI 代理

## 核心原則
1. **Claude 只做三件事**:寫交接規格、啟動、讀報告前 10 行。其餘全部交給代理在背景做,等待期間不要輪詢(背景指令結束會自動通知)。
2. **被交辦者看不到這段對話**,規格必須自給自足(用 `handoff_template.md`),並附 `rules_zh.md`(腳本會自動附上)。
3. **Claude 的用量主要花在「對話有多長」**:長 session 每動一次都要重讀全部歷史。能的話在**新 session** 或剛 compact 後交辦,不要在已經很長的對話裡反覆來回。
4. **不要兩個 session 同時交辦同一件事**(fork 出去的 session 和原 session 都可能收到「Try again」/續做訊息,結果兩邊同時動同一批檔案)。交辦前先確認只有一個 session 在負責。

## 步驟
1. **查額度**:呼叫 `mcp__ccd_session_mgmt__get_usage`(需先 ToolSearch 載入),看 5 小時與本週百分比與重置時間。
   - 5 小時 < 70%:可自己做,也可交辦;使用者明說交辦就交辦。
   - 5 小時 ≥ 70% 或對話已很長:**先只寫規格**(最省),再交辦。
   - 額度已滿:寫不了規格。使用者要自己照 `handoff_template.md` 填,再手動執行腳本(見各 skill 的「手動指令」)。
2. **選代理**(依工作性質,使用者指定的優先):

   | 代理 | 適合 | 注意 |
   |---|---|---|
   | codex（本機） | 寫程式、改程式、跑測試、需要沙盒保護 | 預設 `-s workspace-write`,要寫別的資料夾得 `-AddDir` |
   | grok（本機） | 查資料、分析、一般寫作與小修改 | `-p` 模式不支援額外目錄,`-Cwd` 要選共同上層資料夾 |
   | agy（本機,Antigravity） | 大量讀檔、長流程、可選 Gemini 4 / Claude Opus 5.5 | 預設用 gemini-4-neon-high;自動核准一切 |
   | codex @161 / @005（SSH） | 要用那台機器的資源（GPU、ComfyUI、LoRA 環境、不佔本機） | 檔案不共用,要上傳;**那台可能有人在用**;見 delegate-remote |

3. **寫規格**:複製 `handoff_template.md` 的結構,存成專案資料夾裡的 `SPEC_<主題>_<YYYYMMDD>.md`(**不是磁碟根目錄**)。重點:
   - 已定案的事直接引用使用者原話;不准做的事要明寫。
   - 檔案一律完整路徑;要改的檔案註明「先備份」。
   - 驗收要寫成可執行的指令與通過標準。
   - 不要貼大段程式碼或資料,寫「去讀哪個檔」。
4. **啟動**(用 Bash/PowerShell 的 `run_in_background`):
   - 本機 → 讀 `delegate-local` skill 用 `run_local.ps1`。
   - SSH 到 161 / 005 → 讀 `delegate-remote` skill 用 `run_remote.ps1`。
5. **等通知,只讀 `REPORT.md` 前 10 行**(腳本結束時已印出)。狀態 DONE 才看細節;PARTIAL/BLOCKED 看「需要人決定」。
6. **驗收**:代理說通過不算數。能跑檢查就自己跑一次(例如 TaipeiCity 的 `qa_p01_units.py`、`qa_p01_pdf.py`);額度不夠就在回報裡寫「未驗收」並交給使用者。
7. **善後**:把成果、踩雷寫進記憶或 Obsidian(依全域規則 `updateobsidian`);遠端留下的 `delegate_jobs\<jobid>` 資料夾問使用者要不要刪。

## 已知限制(實測 2026-11-22)
- 三個本機代理都實測通過冒煙測試(寫檔、跑 python、依格式寫報告)。耗時:codex 89 秒、agy 84 秒、grok 185 秒(連極簡任務也要這麼久,不要拿來做需要快速來回的事)。
- codex@161 實測通過(140 秒)。**codex@005 在預設沙盒（workspace-write）下失敗**:SSH 連線中沙盒執行器啟動逾時(`connecting runner pipe-in timed out`),所有讀寫被擋,代理自己回報 BLOCKED。解法只有 `-Full`(關閉沙盒),**尚未驗證**,且需要使用者同意,因為那台代理就沒有沙盒保護。
- 代理在無人看守下是「自動核准一切」。風險靠 `rules_zh.md`、備份、新版號輸出、驗收來控制,不是靠技術上的限制。**重要或不可逆的工作不要交辦**,或交辦時只讓它「寫方案、不動檔案」(規格寫明)。
- 腳本是 ASCII-only(PowerShell 5.1 對無 BOM 的檔案會誤判編碼);中文全放在 `.md` 與 UTF-8 檔裡。
