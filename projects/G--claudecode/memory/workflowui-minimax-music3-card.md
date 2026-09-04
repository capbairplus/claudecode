---
name: workflowui-minimax-music3-card
description: "音樂生成卡 minimax_music3(MiniMax Music 3):內建節點零安裝、核心 template 在 /templates/index.json、seed 要用 SeedNode 同時餵兩個節點、max_duration 只是上限"
metadata:
  node_type: memory
  type: project
  modified: 2026-09-04T00:40:00.000Z
---

**2026-09-04 完成並對真 .161 驗證**:`minimax_music3`(音樂生成,MiniMax Music 3 / 海螺音樂 3.0)。
跟 [[workflowui-minimax-h3-cards]] 同系列,一樣是 **ComfyUI 內建節點、零 custom node**
(`comfy_extras.nodes_minimax_music`:`MiniMaxMusic3TextEncode`、`EmptyMiniMaxMusic3LatentAudio`)。
**是本地權重不是雲端 API 節點**——`/object_info` 裡看 `api_node: false` 就能分辨
(同名的 `MinimaxTextToVideoNode` 那批才是要 API key 的)。

官方 template 是 `audio_minimax_music_3`,主體一樣包在 subgraph 裡要手動展開——
取得端點與展開手法完全照 [[comfyui-builtin-template-subgraph]](**那篇早就記了
`/api/workflow_templates` 只回 custom node 的、核心要打 `/templates/index.json`**,
我這次卻又白繞了一次才想起來——**開工前先讀相關記憶**)。

**⚠ seed 一定要用 `SeedNode` 同時餵給兩個節點**:`MiniMaxMusic3TextEncode` **自己有一顆 seed**
(它生成 acoustic conditioning sequence = 曲子骨架),KSampler 另有一顆。我第一版只把 seed 欄位
綁到 KSampler,結果 `_meta` 顯示 TextEncode 的 seed 永遠停在預設 222——**換 seed 只變取樣細節、
不會換一首曲子**。官方做法是放一顆 `SeedNode`(`comfy_extras.nodes_seed`,輸出 INT)餵兩邊,
manifest 的 seed 欄位改綁 SeedNode。
**驗證手法(通用)**:看 `_meta` 的 workflow,**欄位值是空的就代表接了線而非字面值**。

對照 [[workflowui-minimax-h3-cards]] 的 v2v 教訓:COMBO(檔名)輸入**不能**吃連線,
但 **INT 輸入可以**(LTX 的 `PrimitiveInt`、這裡的 `SeedNode`)。中介節點能不能用要看目標輸入型別。

**其他接線重點**:`CLIPLoader` 的 `type` 填 **`minimax`**(影片音樂共用同一個值);
`EmptyMiniMaxMusic3LatentAudio.seconds` 要**接 `MiniMaxMusic3TextEncode` 的第二個輸出 `seconds`**,
不是自己填數字(長度由 TextEncode 依 `max_duration` 算,兩邊才不會對不上)。

**實測(RTX 4060 Ti 16GB)**:30 步 / `max_duration=30` → **216 秒**(冷載入,輸出只有 16.4 秒)、
**338 秒**(換 seed 重跑,輸出滿 30 秒)。MP3 44.1kHz 立體聲,走 `SaveAudioMP3` 落在 history 的
`audio` key,**後端一行都不用改**。
**⚠ `max_duration` 是上限不是保證**,節點 tooltip 明講模型可能提前結束(實測設 30 只給 16.4 秒),
要撐滿長度得靠歌詞的段落標籤(`[intro]/[verse]/[chorus]/[bridge]/[outro]`)堆結構。

**模型檔(.161,共 14.3GB,HF `Comfy-Org/MiniMax-Music-3`)**:
`minimax_music3_dit_fp16.safetensors` 4.91GB → `diffusion_models\`、
`minimax_music3_text_encoder_pruned_int8_convrot.safetensors` 9.20GB → `text_encoders\`、
`minimax_music3_dav.safetensors` 217MB → `vae\`。
主模型另有 int8_convrot 版(2.5GB,低 VRAM);text_encoder 只有這一版。
**下載方式看 [[comfy-161-model-download-path]]**(這次繞了遠路才學到)。

**定位**:跟既有的 `acestep_music` 平行——ACE-Step 走「曲風標籤+歌詞」快(30 秒音樂 24 秒生成),
Music 3 走「結構化 caption + 歌詞」、支援約 5 分鐘長曲但慢很多。主題曲用 Music 3,試曲風用 ACE-Step。

**⚠ 手動打 `/api/generate` 測試時 `project_path` 和 `scene_folder` 是必填**——少了會拿到
**HTTP 500 且 body 完全空白**(`ProjectPath` 為 null 在 `TrimStart` 炸),不是 400,
很容易誤判成卡片本身有問題。

部署照 [[workflowui-csharp-is-the-real-one]]:JSON 丟進 `workflow_templates\` 和兩個
`bin\Debug\net8.0*\workflow_templates\`,不用 rebuild、不用重啟,`/api/cards` 立刻生效。

相關:[[workflowui-minimax-h3-cards]] [[workflowui-csharp-is-the-real-one]] [[comfy-161-model-download-path]] [[workflowui-vision]]
