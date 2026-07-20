---
name: feedback-save-workflow-per-image
description: 每張生成圖都要把 ComfyUI 提示詞+workflow 設定存進 G: 專案目錄
metadata:
  type: feedback
---

用 ComfyUI 幫使用者生圖時,**每一張圖都要把它的 ComfyUI 提示詞 + 完整 workflow 設定各存一份**到 G: 專案目錄(和圖同一個場景資料夾下,例如 `_meta/` 子夾),檔名對應圖名。

**Why:** 使用者要可重現、可回溯每張圖是怎麼生出來的(哪個底模/LoRA/seed/steps/guidance/解析度/prompt),方便日後重跑或微調。

**How to apply:**
- 每張圖存:①`<prefix>.json`=送給 /prompt 的完整 API graph(內含 model、lora、seed、steps、guidance、寬高、prompt 全部設定);②`<prefix>.txt`=純提示詞(方便閱讀)。
- 放在該場景資料夾的 `_meta\` 子夾,例:`07_photobook\02_home_lounge\_meta\h01.json`。
- 生圖流程見 [[drifter-lora-project]](ComfyUI API + .161)。給檔案位置用純路徑(見 [[feedback-file-links-plain-path]])。
