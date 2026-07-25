---
name: workflowui-vision
description: "WorkflowUI 專案的核心機制與範圍——python 呼叫 ComfyUI API 是底層,web 介面只是彈性參數化外殼"
metadata: 
  node_type: memory
  type: project
  originSessionId: 92ab833c-c89b-4938-aca8-e0caaec12ab3
  modified: 2026-07-25T05:59:32.363Z
---

WorkflowUI(`G:\claudecode\WorkflowUI`)的核心機制:**Web 介面選類別+參數+提示詞,底層用 Python
按照這些選擇組 ComfyUI API 請求打給 .161**。這件事本身已經在跑(既有 su_*.py 腳本),WorkflowUI
只是把它從「每次手寫腳本」變成「介面上選一選、按 generate」。

**使用者 2026-07-25 明確講的範圍**(對話中確認,不是我猜的):

1. **LoRA 要動態列出**,不是寫死清單——從 .161 `/object_info` 掃描 `LoraLoaderModelOnly` 之類節點
   實際裝的 LoRA 檔案。已驗證真的裝了:`anyih_v6/v7/v8`(flux768)、`zhou_yinuo`、`qin_man`、
   `su_ruobing`(su_v2 系列)等角色 LoRA,還有一堆風格/NSFW LoRA。實作見
   `backend/app/routers/comfy_options.py`(`GET /api/comfy/options?class_type=...&input_key=...`)+
   manifest 的 `dynamic_select` 欄位型別。

2. **批次 prompts 用純文字檔,一行一個 prompt**——不是結構化表格。實作是 `RepeatConfig.text_batch_row_key`
   +前端 `renderPromptBatch()`(貼上或上傳 .txt,按行拆),沿用既有的 `repeat` 引擎(每行→一次生成,
   label 自動編號 01/02/...)。

3. **生影片、lip sync 之後再細部設計,但運作方式跟圖生圖同一套**——選類別+參數+prompt→python 組 API 請求
   →打 .161。不用現在就設計 workflow 細節,但擴充時要延續同一個 manifest+workflow_engine 模式,不要另開
   一套機制。

**現況(2026-07-25 更新)**:3 張卡全部 ready、都對真實 .161 驗證過:
- `img2img_qwen`/`multiangle_qwen` — 身分保留靠參考圖(Qwen Image Edit),不用角色 LoRA
- `txt2img_flux` — 不用等使用者匯出 JSON 了,直接在 .161 的
  `D:\ComfyUI_windows_portable\ComfyUI\user\default\workflows\anyih_validation.json` 找到一份已存的
  UI 格式 Flux+LoRA workflow,手動轉成 API 格式後驗證可用,已接上 `dynamic_select`(角色 LoRA 下拉)+
  批次 prompts。以後要找「使用者是否已經在 ComfyUI UI 存過類似 workflow」,先去這個資料夾找,常常比等
  使用者手動匯出快。

圖生影片、lip sync 之後再細部設計,運作方式延續同一套 manifest+workflow_engine 模式。

相關:[[comfy-161-network-access]] [[multiangle-node-plus-text-lesson]]
