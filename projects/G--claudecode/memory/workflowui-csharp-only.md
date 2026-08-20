---
name: workflowui-csharp-only
description: 2026-08-18 起 ComfyUI Cards 只開發 C# 版,不再同步寫 Python 版
metadata:
  type: feedback
---

**2026-08-18 使用者決定:以後開發 ComfyUI Cards 只做 C# 版(`C:\wordpresscb\workflowui-csharp-poc`),
不要再寫 Python 版(`G:\claudecode\WorkflowUI`)。**

**Why**:兩套並存等於每個後端能力都要寫兩遍(2026-08-16 光是「音訊輸出」「影片補音軌」就各寫了兩次
Python + C#),成本翻倍卻沒有對應價值——公開網址 `/comfyuicard/` 反代的是 C# 版(8900),
Python 版(8899)只是開發驗證用。

**How to apply**:
- 新卡片:直接把 `manifest.json` + `workflow_api.json` 放進 C# 版的 `workflow_templates\<id>\`,
  **不用也不要**在 Python 版建一份。卡片是純 JSON 不是程式碼,C# 版的 `ManifestLoader` 每次請求重讀,
  複製到 `bin\Debug\net8.0-windows\workflow_templates\` 就立刻生效、不必重建。
- 後端能力(新輸出型態、前處理…):只改 C#。改到 `.cs` 才需要請使用者用**提權終端機**跑
  stop → `dotnet build` → start(Claude Code 的終端機不是提權的)。
- Python 版現況:留著不動,不必再同步。要驗證新 graph 可以直接對 .161 打 `/prompt`(用
  scratchpad 的 run_graph.py 那種小腳本)就好,不需要先在 Python 版建卡。

**⚠ 2026-08-18 我沒遵守這條**:做 MiniMax H3 四張卡時又先在 Python 版做了一遍才移植,是使用者
問「我怎麼沒在公開網址看到這張卡」才發現。**看到這則就照做,不要再走 Python 那趟。**

**今天補到的操作細節**:
- 卡片做完要走 **C# 的 `/api/generate` 端對端跑一支**(輪詢 `/api/jobs/{id}` 到 `done` 並檢查檔案),
  不能只看 `/api/cards` 有沒有出現。
- **改 `.cs` 後想先驗再上線**:`dotnet build -c Debug -o <暫存目錄>`(Content 規則會一併複製
  `workflow_templates` 與 `wwwroot`),再用**環境變數**換埠跑那份暫存 build 測完整前後端,
  正式服務完全不用停。⚠ `--urls` 沒用,`appsettings.json` 的 `Kestrel:Endpoints:Http:Url` 會蓋掉它,
  要用 `Kestrel__Endpoints__Http__Url=http://127.0.0.1:8901`。
- **Python 版不能直接刪**:它還獨有「長歌曲 Lip Sync MV 專案流程」「匯出獨立執行腳本
  (`/generate/export`)」「SSE 即時進度(`/jobs/{id}/events`)」,C# 版目前沒有這三項。
  另外 114 個自動測試也只在 Python 那邊,C# 專案沒有任何測試。

**⚠ 2026-08-20 又踩一次(這次是連 port 都搞錯)**:使用者說「用 wan_vace 跑一段影片」,我沒查就
假設是 Python 版,還自己 `uvicorn --host 127.0.0.1 --port 8899` 另外開了一個 —— 而機器上早就有
使用者自己的 Python 版常駐在 `0.0.0.0:8899`(pid 從 8/18 活到現在)。兩個一起 bind 8899,
**127.0.0.1 的精確綁定會優先接走本機請求,等於把使用者原本那個遮掉**,使用者才發現。
**動手前先 `Get-NetTCPConnection -State Listen` 看 8900/8899 誰在跑,直接用既有的,永遠不要另起一個。**

**C# 版 API 跟 Python 版不一樣的地方(打 8900 時會踩)**:
- 上傳 `POST /api/uploads` 回傳的是 `{"name": "<uuid>.mp4"}`,**Python 版是 `{"filename": ...}`**。
- 允許的輸出根目錄是 **`C:\wordpresscb\workflowui-output`**,不是 Python 版的 `G:\claudecode`。
  `project_path` 給錯會被擋:`scene path escapes the allowed root ...`。
- 其餘端點同名同形:`/api/cards`、`/api/generate`(body: `card_id`/`project_path`/`scene_folder`/`values`)、
  `/api/jobs/{id}`。前端在 `http://127.0.0.1:8900/app.js`,看不到原始碼時直接抓這支就知道 API 長相。

相關:[[workflowui-postprocess-cards-0816]] [[workflowui-qwen-music-instantid-0816]] [[workflowui-public-url]] [[workflowui-minimax-h3-cards]]
