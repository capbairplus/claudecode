---
name: workflowui-csharp-is-the-real-one
description: WorkflowUI 新卡片一律做在 C# 版 C:\wordpresscb\workflowui-csharp-poc,Python 版 G:\claudecode\WorkflowUI 已不再同步
metadata:
  type: feedback
---

WorkflowUI 有兩套實作,**只有 C# 版是活的**:

- C# 版 `C:\wordpresscb\workflowui-csharp-poc\`(ASP.NET Core,Windows 服務 `WorkflowUiCsharpPoc`,
  port 8900,Apache 反代到公開網址 `/comfyuicard/`)——使用者實際在用的
- Python 版 `G:\claudecode\WorkflowUI`(port 8899)——2026-08-18 起停止同步,只當開發驗證用

**新卡片直接建在 C# 版的 `workflow_templates\<id>\`,不要在 Python 版建一份。**

**Why:** 2026-09-02 我在 Python 版建了五張遮罩卡才被指正,整批要重做移植。Python 版的 README 和
CLAUDE.md 都沒寫這件事,只有 Obsidian 筆記
`D:\capbairvault\ComfyUI\WorkflowUI ComfyUI 卡片架構設計.md` 記著——動 WorkflowUI 前要先讀它。

**How to apply:**
- 卡片是純資料(manifest.json + workflow_api.json),要放**兩個**位置:`workflow_templates\`(原始碼)
  和 `bin\Debug\net8.0-windows\workflow_templates\`(服務實際讀的)。`ManifestLoader` 每個請求重掃磁碟、
  沒有快取,所以丟進 bin 就生效。
- ⚠ **但那只在卡片用的欄位型別是現行 dll 已認得的時候成立**。帶新 `FieldType` enum 值的 manifest 一放進
  bin,整個 `/api/cards` 會 500(JsonStringEnumConverter 解析失敗),全部卡片一起掛。要先 build 再放 JSON。
- 改到 `.cs` 或 `wwwroot\` 才需要重建,而且 `sc.exe stop/start` 與 `dotnet build`(bin 被服務鎖住)
  **都需要提權終端機**,Claude 這邊跑不了,要請使用者跑。
- 驗新卡別只看列表出現,要 `POST /api/generate` 輪詢 `GET /api/jobs/{id}` 到 done。C# 端欄位名跟
  Python 版不同:uploads 回 `name`、generate 回 `job_id`。

相關:[[comfyui-161-launch-output2]]、[[workflowui-vision]]、[[powershell-ssh-quote-trap]]
