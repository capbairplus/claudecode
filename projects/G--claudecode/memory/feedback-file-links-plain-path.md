---
name: feedback-file-links-plain-path
description: 給使用者檔案位置時的偏好與可點連結限制(純路徑 / 工作目錄落差)
metadata:
  type: feedback
---

給使用者檔案位置時,**預設給純 Windows 路徑**(反斜線格式,可整段複製貼到檔案總管),不要只丟 markdown 連結,也不要自作主張用 explorer/Invoke-Item 幫他開檔(他明講不用幫開)。

**Why:** 使用者的專案在 `G:\claudecode\...`(G: 其實是網路磁碟 `\\192.168.3.28\g`),但 Claude Code 桌面版這個 session 的**工作目錄是** `C:\Users\capbair\Documents\claude code desktop`——檔案全在工作目錄之外。Claude Code 的可點連結只解析工作目錄內的檔案,目錄外/網路磁碟/資料夾都點不開(這也是為何他覺得 Codex 能給「開檔/開資料夾」而 Claude Code 不行:Codex 是直接在專案資料夾內啟動,工作目錄對得上)。

**How to apply:**
- 檔案/資料夾位置 → 給純路徑,例:`G:\claudecode\drifter-lora_2026-06-30\zhou_yinuo\04_test\samples`。
- 要「點了就開」看生成圖時 → .161 的 ComfyUI 可當圖床:把圖丟到 `D:\ComfyUI_windows_portable\ComfyUI\output\`,給 HTTP 連結 `http://192.168.1.161:8188/view?filename=檔名&type=output`(需 ComfyUI 開著、同區網)。見 [[drifter-lora-project]]。
- 若要讓連結可點:建議下次**從 `G:\claudecode\` 內啟動 Claude Code**,工作目錄對上檔案位置即可(工作目錄啟動時決定、中途不能改)。
