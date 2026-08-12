# Memory Index

- [WorkflowUI 專案願景與範圍](workflowui-vision.md) — 底層是 python 呼叫 ComfyUI API;LoRA 動態列出、批次 prompts 檔、生影片/lip sync 之後用同一套機制擴充;3 張卡現況
- [.161 網路可達性](comfy-161-network-access.md) — 這個 sandbox 對 .161:8188 的直連可達性會變動(同一 session 內遇過先失敗後通),每次用前先實測,SSH 是穩定備援
- [驗證後才下結論](verify-before-claiming-unreachable.md) — 一次連線失敗不代表「連不到」,下結論前要實際測
- [角度/姿勢類效果要節點+文字雙管齊下](multiangle-node-plus-text-lesson.md) — 只餵數值給控制節點不夠,proven 腳本通常還把描述文字寫進 prompt;漏了會「看起來有跑但沒效果」不報錯
- [影片類卡片要動的後端範圍 + ReActor 沒載入](video-card-pattern-and-reactor-gap.md) — 輸出是影片時「不用改後端」不成立,VHS_VideoCombine 輸出在 `gifs` key;.161 上 ReActorFaceSwap 目前 import 失敗,圖片/影片版換臉卡都受影響
- [WorkflowUI 卡片進度快照 0731](workflowui-cards-progress-0731.md) — wan22_i2v/t2v、infinitetalk_image(圖片對嘴卡)皆已完成並驗證,含技術細節與服務位址
- [長歌曲 Lip Sync MV 設計](workflowui-song-lipsync-mv-design.md) — 多鏡頭模式;第一里程碑(專案+人聲分離+波形編輯器)2026-08-04 完成並通過真實 smoke,下一步是 InfiniteTalk 批次渲染
- [圖片風格轉換卡 style_transfer_qwen](workflowui-style-transfer-card.md) — 沿用 img2img_qwen 已驗證 graph,只調 LoRA 強度;mock 測試全過但尚未對真的 .161 送過生成
- [Solis 包包生成卡 solis_bag_flux](workflowui-solis-bag-card.md) — 複製 txt2img_flux,換 Solis 包款 LoRA(.161 已裝 b19010/b19010_v2/b26 三條);已對真 .161 生成驗證,b19010 系列訓練有問題(模糊,需重練),已改預設用 b26(清晰可用)
- [WorkflowUI 部署到 192.168.1.35](workflowui-deploy-192-168-1-35.md) — Debian、systemd 常駐、連同一個 161;3.31 其實是本機非遠端 ComfyUI;1.35 sudo 需密碼且已跑 WordPress
- [WorkflowUI 對外公開網址](workflowui-public-url.md) — 網域根目錄是本機WordPress(C:\wordpresscb,DB capbairplus_wp);/comfyuicard/(C#版,8900,主力)、/newsradar/(5299)都是反代;改主選單直接寫DB(nav_menu term_id=11)比較快
- [人物轉卡通/政治漫畫人物卡 caricature_qwen](workflowui-caricature-card.md) — 只做 caricature 誇張化、風格內建;三段獨立 concat 讓批次保留共用參數(可複用模式);已對真 .161 驗證
- [姿勢控制卡 pose_controlnet_flux](workflowui-pose-controlnet-card.md) — 角色LoRA+OpenPose ControlNet批次生姿勢,已驗證ready;.161的ControlNet模型清單、單靠骨架幾乎沒用要骨架+文字雙管齊下、strength有seed敏感度不保證張張成功、不寫服裝會生裸體、新增了asset_dir通用機制
