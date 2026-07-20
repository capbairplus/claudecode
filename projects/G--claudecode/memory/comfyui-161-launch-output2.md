---
name: comfyui-161-launch-output2
description: .161 ComfyUI 正規啟動法(cl.vbs)與 output2/input 的 NAS 實際路徑
metadata:
  type: reference
---

.161 ComfyUI 要重啟時,用使用者的正規設定 **`D:\ComfyUI_windows_portable\cl.vbs`**
(Wscript 隱藏執行 `comfyui-listen.bat`)。該 bat:
`python -s ComfyUI\main.py --listen 0.0.0.0 (port 8188) --windows-standalone-build --disable-auto-launch
--output-directory \\solisnas\solisftp\comfyui\output2 --input-directory \\solisnas\solisftp\comfyui\input`

- **「output2」的實際路徑 = `\\solisnas\solisftp\comfyui\output2`**;input = `\\solisnas\solisftp\comfyui\input`(都在 NAS)。
- 別再用會把 output 指到本機 `D:\ComfyUI_windows_portable\ComfyUI\output` 的臨時啟動法(那樣 SaveImage 不進 output2,使用者在 output2 看不到)。
- **NAS 存取前提**:output2/input 在 NAS,啟動 ComfyUI 的帳號要有 NAS 權限。SYSTEM/非互動排程碰不到 NAS(踩過),所以 cl.vbs 最好在**使用者登入 session** 跑(它設計成隱藏跑在桌面)。從 SSH 觸發前先測能否寫 NAS;不行就請使用者點 cl.vbs。
- 註:我的生圖腳本是走 API `/view` 直接把結果存進 G: 專案夾,不依賴 output2;但用 cl.vbs 啟動能讓 SaveImage 也落 output2(使用者慣用檢視處)、且 `/upload/image` 的 reference 會進 NAS input。相關 [[su-ruobing-dataset-progress]] [[drifter-lora-project]]。
