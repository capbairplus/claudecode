# Memory Index

- [WorkflowUI 專案願景與範圍](workflowui-vision.md) — 底層是 python 呼叫 ComfyUI API;LoRA 動態列出、批次 prompts 檔、生影片/lip sync 之後用同一套機制擴充;3 張卡現況
- [.161 網路可達性](comfy-161-network-access.md) — 這個 sandbox 對 .161:8188 的直連可達性會變動(同一 session 內遇過先失敗後通),每次用前先實測,SSH 是穩定備援
- [驗證後才下結論](verify-before-claiming-unreachable.md) — 一次連線失敗不代表「連不到」,下結論前要實際測
- [角度/姿勢類效果要節點+文字雙管齊下](multiangle-node-plus-text-lesson.md) — 只餵數值給控制節點不夠,proven 腳本通常還把描述文字寫進 prompt;漏了會「看起來有跑但沒效果」不報錯
- [影片類卡片要動的後端範圍 + ReActor 沒載入](video-card-pattern-and-reactor-gap.md) — 輸出是影片時「不用改後端」不成立,VHS_VideoCombine 輸出在 `gifs` key;.161 上 ReActorFaceSwap 目前 import 失敗,圖片/影片版換臉卡都受影響
- [WorkflowUI 卡片進度快照 0731](workflowui-cards-progress-0731.md) — wan22_i2v/t2v、infinitetalk_image(圖片對嘴卡)皆已完成並驗證,含技術細節與服務位址
- [長歌曲 Lip Sync MV 設計](workflowui-song-lipsync-mv-design.md) — 多鏡頭模式,設計/計畫已批准但尚未開始執行,預估耗時量級(整首歌約需 8 小時)
