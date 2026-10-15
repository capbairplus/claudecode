---
name: aiwenpdf-license-deferred
description: AiwenPDF 專案暫不處理授權(使用者 2026-10-15 明確指示),但要在對外開放/外賣前主動提醒
metadata:
  type: project
---

AiwenPDF(`D:\myproject\app\AiwenPDF`,要併進 UtilHub `/util/`)現階段**不要討論授權**,先把功能做出來。

**Why:** 使用者 2026-10-15 說「你暫時不要管授權,先做出來,但寫個 memo 提醒我」。

**How to apply:**
- 平常開發不要再提授權、不要在回覆裡附授權警語。
- 但**使用者一提到「對外開放 / 給別人用 / 外賣 / 上架 / 公開網址不限登入」時,必須主動提醒**:先讀 Obsidian `02 Projects/2026-10-15 PDF app 外賣授權與開源注意事項.md` 並跑檢查清單。
- 最需要提醒的點:(1) Office COM 轉檔用的是使用者自己的 Office 授權,對外提供轉檔服務通常不被允許;(2) AGPL 元件(MuPDF/Ghostscript/iText);(3) 微軟字型不能隨產品散布,現用 Noto Sans TC(OFL)沒問題。
- 專案內提醒檔:`D:\myproject\app\AiwenPDF\docs\LICENSE-REMINDER.md`

相關:[[workflowui-public-url]]
