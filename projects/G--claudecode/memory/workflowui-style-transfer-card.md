---
name: workflowui-style-transfer-card
description: "新增圖片風格轉換卡 style_transfer_qwen(2026-08-04)——沿用 img2img_qwen 已驗證 graph,但尚未對真的 .161 送過生成"
metadata: 
  node_type: memory
  type: project
  originSessionId: bfdac695-d2da-46b8-9e6f-54a75ed4df71
  modified: 2026-08-04T01:22:33.042Z
---

2026-08-04 在 `backend/workflow_templates/style_transfer_qwen/` 新增「圖片風格轉換」卡:

- Graph 直接複製 [[workflowui-vision]] 提到已驗證的 `img2img_qwen`(Qwen Image Edit)base,只把
  node 3 的 multiangle LoRA `strength_model` 從 0.55 改成 0.0(避免多角度偏見影響風格轉換品質),
  其餘節點結構完全相同。
- Manifest 欄位:`reference_image`(原始圖)、`prompt`(目標風格文字描述,textarea,預設水彩風格
  範例)、`seed`、`label`(檔名前綴),並沿用 `repeat`/`text_batch_row_key` 機制,支援貼多行風格
  描述一次跑出多種風格版本(同一張參考圖)。
- 已用 mock 測過:`manifest_loader.load_cards()` 能載入、`workflow_engine.build_jobs()` 單張/批次
  兩種模式接線正確、`GET /api/cards` 會回傳這張卡、全套 89 項 pytest 通過。
- **尚未驗證的部分**:建卡當下 .161 上的 ComfyUI 服務沒開著(SSH 進去打
  `curl http://127.0.0.1:8188/system_stats` 回 connection refused),所以沒能實際送一張圖测試
  端到端生成結果。正式使用前應在 .161 開著 ComfyUI 的狀態下,用這張卡跑一次真的生成確認輸出正常。

相關:[[workflowui-vision]] [[comfy-161-network-access]] [[workflowui-cards-progress-0731]]
