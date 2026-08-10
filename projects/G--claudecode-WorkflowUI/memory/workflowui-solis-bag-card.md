---
name: workflowui-solis-bag-card
description: "新增 Solis 包包生成卡 solis_bag_flux(2026-08-06)——複製 txt2img_flux graph 換成 Solis 包款 LoRA,對真的 .161 送過生成,但預設參數輸出偏模糊待調"
metadata: 
  node_type: memory
  type: project
  originSessionId: 9472eae2-17be-4fba-9d10-e61ad9b0d68f
  modified: 2026-08-09T18:09:22.057Z
---

2026-08-06 在 `backend/workflow_templates/solis_bag_flux/` 新增「Solis 包包生成」卡。

**背景**：Solis(明興紡織/solistex.com)除了主業布料,還有一條獨立「包包部門」產品線
(Obsidian `D:\capbairvault\new soliswebsite\Website Content Checklist.md` 提到這條產品線
「unrelated bag business line」,沒被收進網站改版素材)。實際的包款 LoRA 訓練素材、腳本、
輸出都在 `G:\claudecode\SolisProduct\`(不是 WorkflowUI 專案內,是獨立資料夾),包含：
- `dataset/`(b19010 款,含 `raw/product`、`raw/product_cutout`、`raw/model`、
  processed 後的 `img/product_clean`、`img/worn_context` 兩種 caption 情境)
- `dataset_b26/`(b26 款,同樣分 product_clean / worn_context)
- `-/solisb19010bag_flux768*.safetensors`(本地留檔,實際跑圖是用 .161 上已裝好的版本)

**.161 上已確認裝好三條 Solis 包包 LoRA**(用 `/object_info/LoraLoaderModelOnly` 直接查證,
不是猜的)：`solisb19010bag\solisb19010bag_flux768.safetensors`、
`solisb19010bag_v2\solisb19010bag_flux768_v2.safetensors`(重練版)、
`solisb26bag\solisb26bag_flux768.safetensors`。每條都有 5 個 epoch checkpoint。
Trigger word 分別是 `solisb19010bag` / `solisb26bag`,寫在 caption 最前面,例如
product_clean:`solisb19010bag, backpack, product photo, front view, plain white background`；
worn_context:`solisb19010bag, backpack, worn on back with both straps, woman walking away,
back view, full body, indoor graffiti wall background`。

**卡片設計**：直接複製 [[workflowui-vision]] 提到的 `txt2img_flux` graph(不用參考圖上傳,
純文字 prompt + LoRA,使用者確認過這個方向),只改 manifest：
- category 沿用既有 enum 的 `"txt2img"`(schema `manifest_schema.py` 的 category 是
  Literal 白名單,沒有 `"product"` 這個值,加新分類要動 schema+前端,範圍超出這次需求,
  所以沒加)
- `lora_name` 預設指到 `solisb19010bag_v2\solisb19010bag_flux768_v2.safetensors`,
  help_text 列出三條 LoRA 的 trigger word
- 尺寸沿用 768×1024 直式(使用者確認,跟 txt2img_flux 一致)
- prompt 預設帶 product_clean 範例,help_text 附 worn_context 範例可參考

**已驗證,且已排查完模糊問題(2026-08-10)**：`pytest tests/` 104 全過。對真的 .161
跑了 5 組對照生成(同 prompt/seed,只換 LoRA 版本與強度)：
- `solisb19010bag_v2` 強度 0.9 → 模糊
- `solisb19010bag_v2` 強度 0.6 → 模糊
- `solisb19010bag`(v1)強度 0.9 → 模糊
- `solisb19010bag_v2` 第 3 輪 epoch checkpoint → 模糊
- `solisb26bag` 強度 0.9 → **清晰**(乾淨白底商品照,連背包上的品牌標籤文字都清楚)

結論:b19010 這條 LoRA(不管 v1/v2/哪個 epoch/什麼強度)本身訓練有問題,整張圖包含
背景都會模糊失焦,不是卡片接線或參數能救的,**要重新訓練才能用**。b26 這條完全正常。
已把卡片預設 LoRA 跟 prompt 範例都改成 `solisb26bag`,manifest 的 LoRA 欄位
help_text 也註明 b19010 系列先不要選。

相關:[[workflowui-vision]] [[comfy-161-network-access]] [[workflowui-style-transfer-card]]
