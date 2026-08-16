---
name: video-card-pattern-and-reactor-gap
description: "WorkflowUI 加影片類卡片(輸出是影片而非圖片)要動的地方,以及 .161 上 ReActorFaceSwap 目前沒被載入這件事"
metadata:
  type: project
  originSessionId: current
  modified: 2026-08-16T04:14:13.503Z
---

**2026-07-26 新增 `faceswap_video`(影片換臉)卡片時發現**:WorkflowUI 原本的後端/前端只處理過
「輸出是圖片」的卡片,`workflow_templates/<id>/{manifest.json,workflow_api.json}` 那套「不用改後端
程式碼」的說法只在輸出還是圖片時成立。輸出是影片時,實際要動的地方:

1. `backend/app/manifest_schema.py` — `FieldType` 加 `video`(給要上傳的目標影片欄位用,
   `image` 欄位原本寫死 `accept="image/*"`)。
2. `backend/app/routers/generate.py`:
   - `_resolve_and_build`/`_build_for_export` 的上傳判斷從 `f.type == "image"` 改成
     `f.type in ("image", "video")`——上傳本身沒差,ComfyUI 的 `/upload/image` 端點不管檔案
     type、只是把 bytes 存進 input 資料夾(已用 curl 直接對 .161 測試上傳 `.mp4` 成功驗證過)。
   - `_run_job` 的輸出擷取原本只看 `output["images"]`(對應 `SaveImage`/`PreviewImage`),
     `VHS_VideoCombine` 的輸出在 ComfyUI history 裡是放在 `output["gifs"]`(這個 key 名字是
     historical,連真的 mp4/webm 也放在這裡,不是只有 gif)。原本的碼還把副檔名寫死成
     `ext="png"`,如果不修,影片會被存成內容是影片 bytes、副檔名卻是 `.png` 的壞檔。已改成從
     ComfyUI 回傳的實際 `filename` 取副檔名。
   - 同樣的 `images`-only 假設也在 `backend/app/services/script_exporter.py`(匯出腳本的
     `run_one()`)跟 `backend/app/routers/gallery.py`(畫廊列表用 `IMAGE_EXTS` 過濾檔案,影片
     會直接被濾掉不出現)——都已一併修。
3. 前端 `frontend/assets/form-builder.js` 加 `case "video"`(`accept="video/*"`),
   `frontend/card.html` 的 `buildValues()` 上傳判斷同步加 video,`frontend/assets/gallery.js`
   依副檔名判斷渲染 `<video controls>` 還是 `<img>`,`styles.css` 補 `.gallery-item video` 的
   樣式(不然沒有 `width:100%` 版面會爆版)。

**graph 結構(ReActor 版影片換臉)**:`VHS_LoadVideo`(拆幀,輸出 IMAGE batch + audio)→
`ReActorFaceSwap`(`input_image` 直接接整批 frames,`source_image` 接單張來源臉——ReActor 會
逐張處理 batch,這是 ComfyUI 生態圈公認的影片換臉做法)→ `VHS_VideoCombine`(組回影片,
`audio` 接回 `VHS_LoadVideo` 的音軌輸出做 passthrough)。這個模式(拆幀→處理→組回,`gifs` 輸出
key)之後如果要做「圖生影片」「lip sync」之類的卡片,可以直接照抄同一套後端改動,不用重新踩雷。

**⚠ .161 上根本沒有安裝 ReActor**(2026-08-16 更正):`custom_nodes` 底下**沒有任何 ReActor 目錄**,
啟動 log 也沒有 ReActor 的 import 錯誤——所以先前寫的「import 失敗、可能是 insightface/onnxruntime
壞掉」是錯的推測,實際上是**壓根沒裝**。`faceswap_reactor` 和 `faceswap_video` 兩張卡因此都不能用
(送出會拿到 node type not found),要能用得先去 .161 安裝 ComfyUI-ReActor。不能只看 manifest 寫
`status: ready` 就假設能跑。

相關:[[workflowui-vision]] [[comfy-161-network-access]]
