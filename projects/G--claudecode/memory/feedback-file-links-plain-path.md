---
name: feedback-file-links-plain-path
description: 給使用者檔案位置時的偏好與可點連結限制(純路徑 / 工作目錄落差)
metadata:
  type: feedback
---

要給使用者看檔案/圖時,**首選:直接幫他開資料夾**——`Start-Process explorer.exe -ArgumentList "<路徑>"`(PowerShell 工具跑在使用者本機,explorer 會在他桌面跳出檔案總管到該夾)。**這才是他要的「一點就進去」**,不要只丟路徑叫他自己貼。(2026-07 更新:先前記「別自動開檔」已作廢——他明確要求直接開。)

**Why:** 專案在 `G:\claudecode\...`(G: 是網路磁碟 `\\192.168.3.28\g`),但這個 session 工作目錄是 `C:\Users\capbair\Documents\claude code desktop`,檔案全在工作目錄外 → Claude Code 的 markdown 可點連結解析不到(點不開)。但 **PowerShell/Bash 工具是在使用者本機執行,`explorer.exe <路徑>` 能真的開視窗**,所以「直接開資料夾」可行且是最佳解。

**How to apply:**
- 想讓他看圖/檔 → **直接 `Start-Process explorer.exe -ArgumentList "G:\...\資料夾"`** 開給他。(explorer 有時回 exit 1 屬正常,視窗仍會開。)
- 純文字給位置時 → 給純 Windows 路徑(反斜線),別只丟 markdown 連結。
- 要「網頁內嵌可點縮圖」→ .161 ComfyUI 當圖床:`/upload/image`(type=input)上傳後給 `http://192.168.1.161:8188/view?filename=檔名&type=input`。見 [[drifter-lora-project]]。
