---
name: workflowui-caricature-card
description: 人物轉卡通/政治漫畫人物卡 caricature_qwen(2026-08-12)——已對真 .161 驗證;三段獨立 concat 讓批次保留共用參數的模式
metadata: 
  node_type: memory
  type: project
  originSessionId: 050229c9-9869-4493-8ea1-465c594359fc
  modified: 2026-08-11T18:07:21.125Z
---

2026-08-12 在 `backend/workflow_templates/caricature_qwen/` 新增「人物轉卡通 / 政治漫畫人物」卡,
使用者當時明確選的方向:**只做 caricature 誇張化**(不要「保臉只換畫風」那種,那個 style_transfer_qwen
已經有了),風格選單**只放卡片內建**、不接 `G:\claudecode\政治漫畫\styles` 那套 yaml。

- Graph 沿用 [[workflowui-vision]] 的 Qwen Image Edit base,multiangle LoRA 強度 0.0;node 12 的
  `instruction` 改寫成「redraw as exaggerated caricature，但要 recognizable」——原本那句
  "Identity preservation is the priority" 會壓抑誇張化,是這張卡必改的一行。
- **可複用模式:prompt 拆成三段各自獨立的 `StringConcatenate`**(11 畫風 → 19 誇張程度 → 20 附加描述
  → node 12 prompt)。因為批次(`text_batch_row_key`)只 replace 第一段的 `string_a`,誇張程度與附加
  描述會自動套用到批次的每一張。既有卡(style_transfer_qwen / political_cartoon_flux)把多個欄位
  append 進同一個 input,批次時就會被整段蓋掉,只能靠前端 `combine_field` 補救——之後要做「共用參數
  + 批次變動一項」的卡,直接用這個三段式比較乾淨。
- 內建風格 5 類共 46 種:政治/社論漫畫(報紙黑白、港台報紙、Gillray、Daumier、Nast、木刻、刮版、
  鈔票雕版…)、西方卡通、日系動漫、手繪插畫、立體公仔;誇張程度 4 段(輕/中/強/極端)是 select。
- **已對真 .161 驗證**(2026-08-12,ComfyUI 0.18.2 當時開著):用 `anyih_anchor.jpg` 走批次路徑跑
  黑白社論漫畫 + Q版 chibi 兩張,風格、大頭小身誇張、附加情境(皇冠/錢袋/崩塌講台)全部到位且認得出
  是誰。backend 全套 112 項 pytest 通過(含新增的 `tests/test_caricature_card.py`)。
- 踩到的老問題:誇張化會把半身照補成全身,原照穿無袖/細肩帶時補出來的身體只剩內衣——同
  [[workflowui-pose-controlnet-card]] 的「不寫服裝會生裸體」。已寫進附加描述欄的 help_text。

## C# 版(公開網址那套)也已移植並驗證(同日)

照 [[workflowui-public-url]] 的規矩兩邊都做:卡片資料夾整個複製到
`C:\wordpresscb\workflowui-csharp-poc\workflow_templates\`,`dotnet build`(csproj 已有
`workflow_templates\**\*.json` 的 PreserveNewest,不用改 csproj),啟動 exe 後打
`/api/generate` → 輪詢 `/api/jobs/{id}` 到 done,圖片檢查過沒問題。C# 前端本來就支援
`select` / `style_select` / `textarea`,這張卡也沒用到 `mode: append`(三段 concat 的另一個好處),
所以純資料移植、零程式碼修改。

**寫 C# 版驗證腳本會踩的欄位名差異**(跟 Python 版不同,查過原始碼才對):
`POST /api/uploads` 回的是 `{"name": ...}` 不是 `stored_name`;`POST /api/generate` 回的是
`{"job_id": ...}` 不是 `id`(但 `GET /api/jobs/{id}` 快照裡那個欄位又叫 `id`)。

相關:[[workflowui-style-transfer-card]] [[workflowui-vision]] [[comfy-161-network-access]]
[[workflowui-public-url]]
