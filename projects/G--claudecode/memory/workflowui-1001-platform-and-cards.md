---
name: workflowui-1001-platform-and-cards
description: 2026-10-01 一晚做完的 C# 版改動(15 區分類、成果接力、參數回填、SeedVR2/SAM3/MSR 新卡、修 ReActor 卡、LaMa 下架)與端對端測試做法
metadata:
  type: project
---

使用者 2026-10-01 說「照規劃動工、分類要分好」後完成(C# 正式版 `D:\myproject\ComfyuiCard`):

- **分類**:首頁 9 區 → 15 區(圖片拆 編輯/換臉/局部修補/後製;影片拆 生成/對嘴數位人/後製;
  語音卡 category 從 `music` 改 `tts`)。對應表在 `index.html` 的 `CATEGORY_BUCKET`,舊 `?cat=` 有別名相容。
- **成果接力**「➡️ 送到…」(card 成果區 + 畫廊):sessionStorage 帶檔 → 目標卡 `?handoff=1` →
  DataTransfer 塞進 `<input type=file>` 觸發 change,沿用原本上傳/遮罩載入流程。純前端,已上線。
- **參數回填**「↺ 用這組參數」:後端每個輸出寫 `_meta/<stem>.params.json`、新 API
  `/api/gallery/params`、`/api/cards` 附 `inputs`、`/api/health` 匿名只回 ok。**.cs 改動要使用者
  以管理員跑 `restart_service.bat` 才生效**(當晚未重建)。
- **新卡**:`upscale_seedvr2`(1MP 2x 22s/4x 70s)、`video_upscale_seedvr2`(3.5s 片 2x 約 5.5 分)、
  `segment_sam3`(中文提示詞弱,要英文)+ 遮罩畫布「✨ 自動遮罩」、`ltx23_msr`(97 幀約 4 分)。
  權重已放 .161(SeedVR2 3B int8 + VAE、sam3.1)。
- **修/下架**:faceswap_reactor/video 改 mtb(見 [[mtb-faceswap-batch-pitfall]]);LaMa 卡移到
  `retired_templates`(iopaint 在 py3.13/numpy 新版有維度錯誤,補 imghdr 也救不了)。

**端對端測試做法**(不碰正式站):`dotnet build -o <scratch>\testbuild`,刪掉 testbuild\data\users.json
讓它自建一次性 admin,用 `--Kestrel:Endpoints:Http:Url=` 開在別的埠。坑:8901 已被
`D:\MyProject\ConfyuiCard-Desktop` 佔用;`C:\ProgramData\WorkflowUI\settings.json` 覆蓋設定是共用的,
所以測試輸出仍寫進正式輸出根目錄(測完要搬走);session cookie 是 Secure,Python 要用 Bearer token;
Git Bash 會把 `/api/...` 參數轉成 `C:/Program Files/Git/api/...`,要 `MSYS_NO_PATHCONV=1`。

相關:[[workflowui-csharp-is-the-real-one]] [[comfy-output2-vanishing-files]]
