---
name: workflowui-qwen-music-instantid-0816
description: 2026-08-16 第三批卡片(Qwen Edit 五張、ACE-Step 音樂、InstantID)與為此在 .161 補裝的東西、音訊輸出機制
metadata: 
  node_type: memory
  type: project
  originSessionId: 43c61d1b-8971-4d1f-89e6-6b9ae04e3a27
  modified: 2026-08-16T07:46:03.096Z
---

2026-08-16 第三批,共 7 張卡,全部對真 .161 驗證過(接續 [[workflowui-postprocess-cards-0816]]):

**Qwen Edit 四張**(`outfit_qwen` 換服裝 77s、`bg_replace_qwen` 背景替換 36s、`restore_qwen`
老照片修復上色 56s、`product_scene_qwen` 商品情境圖 164s)。**做法是直接複製已驗證的 graph**:
單圖的複製 `style_transfer_qwen`(multiangle LoRA 歸零)、雙圖的複製 `faceswap_qwen`
(`QwenEditConfigPreparer` 用 `configs` 串接兩張圖,第二張 `ref_main_image: false`),
只改 `TextEncodeQwenImageEditPlusCustom_lrzjason` 的 `instruction` 跟預設 prompt。
**這是新增 Qwen 類卡片最省事也最安全的模式,之後照抄就好。**

**`social_resize`**(社群多尺寸外擴):不是 Qwen,是 SDXL 路線 ——
`ImagePadForOutpaintTargetSize`(輸出 IMAGE + MASK)→ `InpaintModelConditioning`(noise_mask=true)
→ KSampler denoise 1.0。原圖像素被 mask 保護不會被改,只填補出來的空白。768×1024 → 1920×1080
約 48 秒,效果很好。目標寬高用兩個 `INTConstant` 餵給同一組節點。

**`acestep_music`**(音樂生成):`ace_step_v1_3.5b.safetensors`(7.7GB)下載到 `models\checkpoints\`。
graph = CheckpointLoaderSimple → TextEncodeAceStepAudio(tags + lyrics)→ ConditioningZeroOut 當負向
→ EmptyAceStepLatentAudio(seconds)→ ModelSamplingSD3 shift 5 → KSampler(50 步 CFG 5)→
VAEDecodeAudio → SaveAudioMP3。**30 秒音樂只花 24 秒生成**,速度非常快。
**新機制:音訊輸出**。`SaveAudioMP3` 在 history 裡是 `outputs[node]["audio"]`,結構跟 images 一樣,
所以只要把 `audio` 加進 media_items 就好(比文字輸出簡單)。Python `routers/generate.py` +
`gallery.py` 的 `AUDIO_EXTS` + `gallery.js` 的 `<audio>`;C# `GenerateService.cs` + `Program.cs`
的 content-type + `card.html` 的 `result-audio`。新 category:`music`。

**`faceswap_instantid`**(併入既有 `faceswap` 群組):.161 原本**根本沒裝 ComfyUI_InstantID**
(只有 comfyui_ipadapter_plus),所以節點才不存在。補裝內容:
1. `git clone https://github.com/cubiq/ComfyUI_InstantID` 到 custom_nodes(依賴 insightface +
   onnxruntime 都已有,**不用 pip**)。
2. `models\instantid\ip-adapter.bin`(1.7GB)、`models\controlnet\instantid_control.safetensors`
   (2.5GB,來源是 InstantX/InstantID 的 `ControlNetModel/diffusion_pytorch_model.safetensors`)。
   antelopev2 本來就在 `models\insightface\models\`。
3. **重啟 ComfyUI 才會載入**——照 [[comfyui-161-upgrade-0816]] 記的安全做法:`Stop-Process` 掉舊的
   `python_embeded\python.exe` → `schtasks /Run /TN comfyui`,不會在 chavi 螢幕上彈視窗。實測有效。
graph 用 `ApplyInstantIDAdvanced`(ip_weight / cn_strength 分開調)+ SDXL juggernautXL,30 步 CFG 5。
⚠ **第一次實測就踩到「prompt 不寫服裝就生裸體」**(跟 [[workflowui-pose-controlnet-card]] 同一個雷),
預設 prompt 已補服裝、負向詞加 nude/nsfw。

相關:[[workflowui-postprocess-cards-0816]] [[workflowui-vision]] [[workflowui-public-url]]
