---
name: feedback-file-links-plain-path
description: 提到任何生成/修改的檔案或文件,同一則訊息就附完整絕對路徑(可點連結+純路徑),別只寫檔名;可點連結的限制與替代方案
metadata:
  type: feedback
---

**2026-10-09 最新規則(使用者明確要求,最優先):** 只要這則回覆提到我生成、修改或要使用者去看的任何文件/檔案,**就在同一則訊息直接附完整絕對路徑**,而且要是可點的:寫成 markdown 連結 `[檔名](絕對路徑)`,旁邊再附純 Windows 路徑(反斜線,放行內程式碼)當保險。**絕對不要只寫檔名**,也不要等使用者追問「在哪」。同一個檔案在後面幾輪再提到時也一樣要附,不能因為前面給過就省略。

**Why:** 連續兩次(`apache-dwgest.conf`、`待補資料清單.md`)只寫檔名,使用者得自己問「在哪」,他明確表示「給個 path 有那麼難嗎」。

**例外/陷阱(2026-10-09):** 網頁應用的 `index.html` 之類原始碼**不要當成「入口」貼成可點連結**。使用者點下去會用 `file://` 直接開檔,頁面的相對路徑 API 全部 `Failed to fetch`,他會以為「登入不進去」(DWG 估價網站就踩過,我還誤判成瀏覽器擴充功能擋請求)。提到網頁應用時:**先給網址**(例 `https://capbairplus.duckdns.org/dwgest/`),原始碼檔另外標明「這是原始碼,不是網站」,必要時只給純路徑不給連結。

**How to apply:** 檔案在 session 工作目錄外(例如 `D:\myproject\...`)時 markdown 連結可能解析不到,所以純路徑那份一定要給;必要時用 `mcp__ccd_directory__request_directory` 把該資料夾加進 session 讓連結能點。同理,別每回合結尾都反覆問「要不要 updateobsidian」,他要時自己會下指令。

要給使用者看檔案/圖時,**首選:直接幫他開資料夾**——`Start-Process explorer.exe -ArgumentList "<路徑>"`(PowerShell 工具跑在使用者本機,explorer 會在他桌面跳出檔案總管到該夾)。**這才是他要的「一點就進去」**,不要只丟路徑叫他自己貼。(2026-07 更新:先前記「別自動開檔」已作廢——他明確要求直接開。)

**Why:** 專案在 `G:\claudecode\...`(G: 是網路磁碟 `\\192.168.3.28\g`),但這個 session 工作目錄是 `C:\Users\capbair\Documents\claude code desktop`,檔案全在工作目錄外 → Claude Code 的 markdown 可點連結解析不到(點不開)。但 **PowerShell/Bash 工具是在使用者本機執行,`explorer.exe <路徑>` 能真的開視窗**,所以「直接開資料夾」可行且是最佳解。

**How to apply:**
- 想讓他看圖/檔 → **直接 `Start-Process explorer.exe -ArgumentList "G:\...\資料夾"`** 開給他。(explorer 有時回 exit 1 屬正常,視窗仍會開。)
- 純文字給位置時 → 給純 Windows 路徑(反斜線),別只丟 markdown 連結。
- 要「網頁內嵌可點縮圖」→ .161 ComfyUI 當圖床:`/upload/image`(type=input)上傳後給 `http://192.168.1.161:8188/view?filename=檔名&type=input`。見 [[drifter-lora-project]]。
