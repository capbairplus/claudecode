---
name: feedback-batch-gen-workflow
description: ComfyUI 批次生圖流程:一次派遣→單一長等收圖→只在岔路才問,別頻繁打擾
metadata:
  type: feedback
---

用 ComfyUI 批次生圖時,**不要把「等待+抓圖」切成很多段短輪詢**(那會產生一堆工具呼叫,每次都跳授權,使用者覺得像一直在請示)。

**Why:** 使用者明講「圖都生好了還一直要我按確認…過程太頻繁」。他要的是:提示詞寫好就派給 ComfyUI 執行,別一直來回敲他。真正惹人煩的是抓圖用了十幾次輪詢指令,不是在等他確認。

**How to apply:**
- **一次派遣**:整批 prompt 一次全 POST 到 /prompt。
- **派出去後「完全安靜」**:使用者明令「comfyui 任務全部跑完再通知我,中間沒狀況不要再發訊息」。所以派完到交件之間**不冒任何訊息、不做一段段前景輪詢**(前景輪詢每段都會跳授權=打擾)。
- **收圖用「單一背景收集器」**:`run_in_background: true` 丟一支背景程式,內部 loop 一路等到**整批收齊**、順便做好總覽/serve,然後才退出通知我 → 我再**一次**交件。中途不出聲。
- **只有兩種情況才中途出聲**:整批完成、或真的出狀況(例如生成崩速/報錯)。
- **只在真正岔路才問**(換場景/風格轉向/尺度);routine 進度絕不打擾。見 [[feedback-discuss-not-menu]]。
- 可建議使用者把固定的 python/ComfyUI 抓圖指令加進 permissions 允許清單(見 update-config skill),之後完全不跳授權。
- 生圖環境/做法見 [[drifter-lora-project]];每張仍要存 workflow 見 [[feedback-save-workflow-per-image]];別自作主張見 [[feedback-only-do-what-asked]]。
