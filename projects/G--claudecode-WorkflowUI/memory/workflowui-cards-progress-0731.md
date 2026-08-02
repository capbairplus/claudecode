---
name: workflowui-cards-progress-0731
description: WorkflowUI 卡片完成進度快照(2026-07-31)——Wan22 I2V/T2V、InfiniteTalk 圖片對嘴卡皆已完成並驗證
metadata: 
  node_type: memory
  type: project
  originSessionId: ed452add-ec23-41f1-a556-2d50e0619a5c
  modified: 2026-08-02T05:17:51.360Z
---

截至 2026-07-31,WorkflowUI(`G:\claudecode\WorkflowUI`)除了 [[workflowui-vision]] 提到的 4 張圖片卡
(`img2img_qwen`/`multiangle_qwen`/`expr_qwen`/`txt2img_flux`)外,又完成:

- **`wan22_i2v` / `wan22_t2v`**(Wan 2.2 影片生成,群組「Wan 2.2 影片生成」):固定 4 steps、CFG 1、
  high/low noise 各 2 steps、shift 5,用 4-step Lightning LoRA 求短生成時間。T2V 實際生成約 5 分 36 秒,
  輸出 576×896、81 frames、16 FPS。兩張都已 smoke 驗證成功(完整回歸 54 passed)。
- **`infinitetalk_image`**(圖片對嘴卡,群組 `lip_sync`/`Lip Sync`):proven workflow 來自
  `InfiniteTalk03.json`。輸入:人物圖片、WAV/MP3/M4A 音訊、說話/唱歌模式、輕微/自然/活潑動作幅度、
  簡短動作描述、Seed、輸出名稱。第一版音訊上限 10 秒(超過拒絕送出並提示裁切)。自動判斷橫直圖
  (832×480 / 480×832),完整保留圖片不裁切、空缺補黑邊。音訊先用 ffmpeg 轉 48kHz stereo PCM WAV,
  影片幀數依音訊長度算成合法的 `4n+1`,輸出再 trim 到音訊長度。系統會依音訊長度、模式、動作幅度、
  使用者描述**自動組出英文時間軸 Prompt**(呼應 [[multiangle-node-plus-text-lesson]] 的「節點+文字
  雙軌」教訓,這裡是進階版:文字要對齊時間軸)。核心設定:Wan2.1 I2V 480p 14B FP8 + InfiniteTalk
  Single FP8 + 中文 Wav2Vec2 + LightX2V rank64、6 steps、CFG 1、DPM++ SDE、25 FPS、H.264 CRF19。
  最新完整回歸 72 passed,實際 smoke(3.5 秒音訊)Comfy 執行約 870.6 秒(14 分 31 秒)。

**服務位址**:`http://192.168.3.31:8899`(本機 `127.0.0.1:8899`)。已加入工作階段進度/百分比/ETA 顯示、
`POST /api/jobs/{job_id}/cancel` 可中斷、影片輸出改從 manifest 指定的 output node 下載(避免抓到中間
預覽影片)、輸出目錄改由使用者自選(主要測試輸出放 `G:\claudecode\output`)。

相關文件路徑(spec/plan/verification 都在 `G:\claudecode\WorkflowUI\docs\superpowers\` 底下,
檔名前綴 `2026-07-30-infinitetalk-image-lipsync-*`)。

**下一步方向**:規劃中的「長歌曲 Lip Sync MV」功能,見 [[workflowui-song-lipsync-mv-design]]。

相關:[[workflowui-vision]] [[workflowui-song-lipsync-mv-design]] [[video-card-pattern-and-reactor-gap]]
