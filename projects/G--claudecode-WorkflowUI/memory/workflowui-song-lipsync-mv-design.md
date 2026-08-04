---
name: workflowui-song-lipsync-mv-design
description: "WorkflowUI 長歌曲 Lip Sync MV 功能——已批准的產品方向;第一里程碑(歌曲專案+人聲分離+波形編輯器)已於 2026-08-04 完成並通過真實 smoke 驗證"
metadata: 
  node_type: memory
  type: project
  originSessionId: ed452add-ec23-41f1-a556-2d50e0619a5c
  modified: 2026-08-04T02:01:04.000Z
---

**目標**:在 WorkflowUI 裡做出 3 分鐘以上歌曲的 Lip Sync MV,而不是把整首歌硬塞給單一 InfiniteTalk
工作(那樣估計要跑非常久)。

**已批准的產品方向**(設計完成,尚未實作):

- 「多鏡頭 MV 模式」:只在清楚露臉演唱段用 [[workflowui-cards-progress-0731]] 提到的 `infinitetalk_image`
  做 Lip Sync;前奏、間奏、尾奏、遠景及情境畫面直接沿用專案素材庫中既有的 I2V/T2V 影片(即
  `wan22_i2v`/`wan22_t2v` 產出)。
- 上傳完整歌曲後,先分離人聲 stem(重用 `.161` 現有的 `FL_Audio_Separation`,**不裝新的大型 ML 套件**),
  再用人聲能量自動找出演唱區段。小於約 0.5 秒的空隙自動合併;長人聲區切成約 8–12 秒片段。
- 介面:完整歌曲波形、播放游標、縮放、點擊播放、可拖曳起訖點、新增/刪除/分割/合併片段。第一版
  **不支援** `.lrc` 或歌詞辨識。
- 人物鏡頭圖片庫,系統自動輪替且避免相鄰片段用同一張,使用者仍可逐段手動改。
- 每段可選 `Lip Sync` 或 `素材`,轉場可選直接切鏡或約 0.25 秒交叉淡化。
- 專案固定橫式 832×480 或直式 480×832(跟 `infinitetalk_image` 的橫直判斷一致)。
- 每段是獨立工作,支援暫停/立即中斷/續跑/跳過已完成/重跑單段/重跑失敗片段。
- 最終合成移除各片段音軌,只掛回完整原始歌曲,避免節拍/音量/接縫漂移。
- 時間預估用本機實際歷史速度動態算——以現有 smoke 推算,若整首歌約 120 秒需要 Lip Sync,初始估算
  可能接近 8 小時,**這是使用者需要被提前告知的量級**,不是幾分鐘等級的功能。

**第一個小里程碑(2026-08-04 完成並通過真實 smoke 驗證)**:

1. 歌曲專案 JSON 與素材持久化。✅ `backend/app/song_projects/{models,store}.py`
2. 重用 `.161` 現有 `FL_Audio_Separation`。✅ `backend/app/song_projects/separation.py`——**實測 `SaveAudio` 真正輸出 `.flac`(不是 `.wav`),history 的 key 是 `"audio"`**;程式依實際回傳檔名取副檔名,不寫死,避免重蹈影片卡的副檔名雷。
3. 建立人聲 waveform peaks 與自動 8–12 秒演唱片段。✅ `backend/app/song_projects/analysis.py`
4. 非人聲區自動建立 `media` placeholder,讓時間軸覆蓋整首歌曲。✅
5. 原生 Canvas 波形編輯器,不依賴 CDN。✅ `frontend/song-lipsync.html` + `frontend/assets/song-waveform.js`
6. 支援拖曳/新增/分割/合併/刪除/保存,服務重啟後可恢復。✅——**手動瀏覽器測試時抓到兩個真實 bug**:
   (a) 拖曳兩個相鄰片段的共用邊界時數值會彈回原位(`_preventOverlap` 把拖曳中的片段夾回「尚未移動的鄰居」),已修正為偵測共用邊界並讓兩段邊界一起移動(像可拖曳分隔線)。
   (b) 更嚴重:任何一次片段編輯儲存都可能回傳 400,跟改哪一段無關——因為 `serializeSegments()` 把時間四捨五入到 0.01 秒,若最後一段結束時間恰好等於歌曲長度(浮點數,如 `20.035918`),四捨五入後可能變成 `20.04` 而超出原始 duration,`SongProject` 驗證器零容忍就整包拒絕。修法:`models.py` 的範圍檢查加 0.01 秒容忍度。**這個 bug 只有透過真的跑分析(拿到非整數的真實 duration)+ 真的存一次片段才會現形,mock 測試測不出來**。
7. 完成 20–30 秒真實歌曲分析 smoke 後停止,交使用者審閱,再進入 InfiniteTalk 批次生成與最終 MV 合成。✅ 用本機 ffmpeg 合成的 25 秒測試音訊(非真實歌曲)跑完整流程:建立專案→分析→拖曳/分割/合併片段→確認時間軸→重啟伺服器後仍正確恢復。

新增的 API:`POST/GET /api/song-projects`、`GET /api/song-projects/{id}`、`POST /api/song-projects/{id}/analyze`(重用既有 `job_manager`+`/api/jobs/{id}` SSE 機制回報進度)、`PUT /api/song-projects/{id}/segments`、`POST /api/song-projects/{id}/confirm`。

驗證文件:`G:\claudecode\WorkflowUI\docs\superpowers\verification\2026-08-04-song-analysis-editor-smoke.md`

**之後階段(下一步,尚未設計細節)**:InfiniteTalk 分段批次渲染 → 素材配置/轉場/完整原曲 MV 合成。

相關文件:
- `G:\claudecode\WorkflowUI\docs\superpowers\specs\2026-07-30-song-lipsync-mv-design.md`
- `G:\claudecode\WorkflowUI\docs\superpowers\plans\2026-07-30-song-lipsync-analysis-editor.md`
- `G:\claudecode\WorkflowUI\docs\superpowers\verification\2026-08-04-song-analysis-editor-smoke.md`

相關:[[workflowui-cards-progress-0731]] [[workflowui-vision]]
