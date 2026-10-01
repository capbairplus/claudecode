---
name: mtb-faceswap-batch-pitfall
description: .161 的 Face Swap (mtb) 吃多幀 batch 會算壞、預設 preserve_alpha 會讓影片全黑;影片換臉要先拆成 list 逐幀跑
metadata:
  type: project
---

2026-10-01 把 `faceswap_reactor`/`faceswap_video` 從(沒安裝的)ReActor 改成 `Face Swap (mtb)` 時踩到:

- **batch 會算壞**:直接把 `VHS_LoadVideo` 的多幀 IMAGE 接進 mtb 換臉,輸出變成 (480,3,3) 這種碎片,
  不報錯。單張圖才正常。解法:`ImpactImageBatchToImageList` → mtb(ComfyUI 會逐幀呼叫)→
  `ImageListToImageBatch`。(`ImageBatchToImageList` 這個名字在 .161 不存在,要用 Impact 版。)
- **preserve_alpha 預設 true → 影片全黑**:回傳 RGBA 幀,VHS 編 h264 變黑畫面。影片要設 `false`。
- inswapper 只有 128px,大圖臉偏糊;圖片卡後面接可開關的 FaceDetailer(denoise 0.35,
  `ImpactConditionalBranch` lazy 開關)就清楚很多。實測:只換臉 3 秒、加精修約 30~100 秒;
  影片 85 幀約 6 分鐘(~4 秒/幀)。
- 舊 manifest 的 frame_rate 欄位寫死 24,改接 `VHS_VideoInfoLoaded` 跟隨原片 FPS。

相關:[[video-card-pattern-and-reactor-gap]] [[workflowui-1001-platform-and-cards]]
