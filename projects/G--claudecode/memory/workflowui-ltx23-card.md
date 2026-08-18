---
name: workflowui-ltx23-card
description: "LTX 2.3 卡片的前置作業狀態——.161 上模型檔已補齊可被載入,以及 LTX 版本/VRAM 路線的正確理解"
metadata: 
  node_type: memory
  type: project
  originSessionId: b37f599c-ad07-48af-bb4a-5fffdf0b55b9
  modified: 2026-08-16T04:14:02.113Z
---

**LTX 版本脈絡**(2026-08-16 查證):LTX 2.3 是 2026-03 的版本;**LTX-2.5 在 2026-08-11 發布**
(開源權重、ComfyUI day-0 支援、自動時長預測)。ComfyUI 內建 template 兩者都有:
`video_ltx2_3_{t2v,i2v,ia2v,flf2v,ic_lora,id_lora}.json`、`video_ltx2_5_{t2v,i2v,flf2v}.json`
(在 `python_embeded\Lib\site-packages\comfyui_workflow_templates_json\templates\`)。做卡片時直接
拿這些當 proven graph,不要自己從零拼。

**VRAM 的正確理解**(我一開始講錯過):官方講的「22B fp8 25.2GB + Gemma fp4 9.5GB ≈ 35GB」是
**全部塞進 VRAM 不 offload** 的配置,不是門檻。實際路線是**量化 GGUF + offload**:Q4_K_M 只有
13.3GB,Gemma 可丟 CPU,ComfyUI 自動把裝不下的權重串流到系統 RAM。社群在 8GB 卡上都跑得動,
.161 的 **RTX 4060 Ti 16GB + 68GB RAM** 寬鬆得多。**VRAM 決定的是速度,不是能不能跑。**

**.161 上目前已備妥**(2026-08-16 補齊,全部已驗證出現在對應 loader 的選項裡):
| 檔案 | 大小 | 位置 |
|---|---|---|
| `ltx-2.3-22b-dev-Q4_K_M.gguf` | 13.34GB | `models\unet\`(**hardlink**,本體在 `models\checkpoints\ltxv\`) |
| `gemma_3_12B_it_fp4_mixed.safetensors` | 9.45GB | `models\text_encoders\` |
| `ltx-2.3-22b-dev_embeddings_connectors.safetensors` | 2.31GB | `models\text_encoders\` |
| `ltx-2.3-22b-dev_video_vae.safetensors` | 1.45GB | `models\vae\` |
| `ltx-2.3-22b-dev_audio_vae.safetensors` | 0.36GB | `models\vae\` |

GGUF 原本放在 `checkpoints\ltxv\`(chavi 2026-04-27 抓的),而 `UnetLoaderGGUF` 只掃 `models\unet\` 和
`models\diffusion_models\` —— 這大概就是它擺了四個月沒下文的原因。用 hardlink 而非搬移,兩邊路徑都在。

GGUF header 顯示 `general.architecture = ltxv`(在 ComfyUI-GGUF `loader.py` 的 `IMG_ARCH_LIST` 裡)、
config 是 `AVTransformer3DModel` → **會同步生音訊**,做卡片時輸出要確認帶音軌。

**⚠ sigmas 千萬別拿錯階段**(2026-08-16 踩過):官方 t2v template 裡有兩條 `ManualSigmas`——
- `1.0, 0.99375, 0.9875, 0.98125, 0.975, 0.909375, 0.725, 0.421875, 0.0`(8 步,**從 1.0 起**)
  = **第一階段**,從純噪音生成。單階段 workflow 要用這條。
- `0.85, 0.7250, 0.4219, 0.0`(4 步,從 0.85 起)= **第二階段**,接在已生成 latent 上 refine。

我一開始拿第二階段那條當第一階段用,**不報錯**,但畫面顏色暗淡、人物糊、對比低——等於一開始就假設
畫面已有八成內容,實際餵進去的是純噪音,還跳過最關鍵的高噪音區段。改用 8 步那條後,同 seed 同尺寸的
h264 檔案大小接近翻倍(768×512:558KB → 1070KB),細節回來了。**LTX 出圖糊,先檢查 sigmas 起始值
是不是 1.0。**

**實測速度**(RTX 4060 Ti 16GB;下表是 4 步版,8 步版 768×512 約 110 秒、512×320 約 75 秒):
| 解析度 | 長度 | 耗時 | VRAM 峰值 |
|---|---|---|---|
| 512×320 | 2 秒 | 91 秒(含首次載入) | 14.4GB |
| 768×512 | 4 秒 | 137 秒 | 14.8GB |
| 1280×704 | 5 秒 | 183 秒 | 13.4GB |

VRAM 全程穩在 13–15GB 沒溢出,遠優於 `wan22_t2v` 的 5 分 36 秒。**耗時差異主要來自模型載入/卸載**
(13GB GGUF + 9.4GB Gemma):同批連續跑最快只要 50 秒,中間插別的卡片把模型擠出快取就要多付 2–3 分鐘
——做卡片時值得考慮批次連跑。

高度會被對齊到 **32 的倍數**(指定 720 會變成 704),做卡片時後端要先對齊,否則靜默改尺寸。

單階段 t2v 的 API graph(已驗證可跑)存在 scratchpad 的 `ltx_batch.py`:UnetLoaderGGUF →
LoraLoaderModelOnly(distilled LoRA 0.5)→ LTXAVTextEncoderLoader(gemma + connectors,connectors 要
**hardlink 到 `checkpoints\ltxv\`** 才選得到,因為該節點的 `ckpt_name` 只吃 checkpoints 清單)→
CLIPTextEncode ×2 → LTXVConditioning → EmptyLTXVLatentVideo + LTXVEmptyLatentAudio →
LTXVConcatAVLatent → SamplerCustomAdvanced(CFGGuider cfg=1、euler)→ LTXVSeparateAVLatent →
VAEDecode + LTXVAudioVAEDecode → CreateVideo → SaveVideo(輸出在 history 的 `images` key,`animated: true`)。

**卡片已建立**(2026-08-16),兩張共用 group `ltx23_video`(UI 上是一張卡、用 select 切換):
- `ltx23_t2v`(快速)— 單階段 8 步,output_node 21。768×512 4 秒約 2 分鐘。
- `ltx23_t2v_hq`(高畫質)— 兩階段 + spatial upscale(`ltx-2.3-spatial-upscaler-x2-1.1.safetensors`
  已下載到 `models\latent_upscale_models\`),output_node 35。寬高填的是**第一階段**,輸出是 2 倍
  (預設 640×384 → 1280×768),4 秒約 6 分鐘。

兩張都有批次 prompts(`text_batch_row_key`)+ seed 遞增。**幀數用一個 `PrimitiveInt`(node 40)同時
餵給 `EmptyLTXVLatentVideo.length` 和 `LTXVEmptyLatentAudio.frames_number`** —— manifest 一個欄位只能綁
一個 node/input,要同步兩處就靠中介 Primitive 節點,這個模式其他卡也能用。

`SaveVideo` 的輸出落在 history 的 **`images`** key(不是 `gifs`),而 `routers/generate.py` 已經同時
讀 `images`/`gifs`/`audio`,所以**後端完全不用改**。

寬高欄位用 `integer` 不用 `select`:`workflow_engine._set_input` 不做型別轉換,select 的值是字串,
寫進 INT 輸入有風險。

**驗證狀態:全部通過(2026-08-17 完成端對端)**。manifest 載入 OK(兩張都 ready)、114 個既有測試
全過、節點/參數驗證零 findings、透過 WorkflowUI `/api/generate` 實際生成成功:
768×512 / 97 幀 / 8 步,**每步 10.64 秒、整支 204.68 秒(3.4 分鐘)**,輸出 h264 768×512 4.04 秒 +
aac 48kHz 立體聲 4.01 秒,檔案正確落在 `scene_folder` 底下。

`ltx23_t2v_hq` 也在 2026-08-17 完成端對端:640×384 → 輸出 **1280×768**、4.04 秒 + aac 音軌,
耗時 **617 秒(10 分 17 秒)**,第一階段 32.35s/it、第二階段 21.38s/it。注意這次跑的時候 ollama
還佔著約 2.2GB,所以比 GPU 全空時直送同一個 graph 的 **354 秒**慢了將近一倍——**2GB 的差距就足以
讓 13.4GB 的模型開始 offload**,可見這張卡對顯存有多敏感。

**2026-08-18 才移植到 C# 版**(8900,公開網址背後那套;2026-08-16 做卡時漏了這步,所以公開網址上
一直看不到這兩張)。移植就是把資料夾複製到 `workflow_templates\` 和 `bin\Debug
et8.0-windowsworkflow_templates\`,不用 rebuild 也不用重啟服務。C# 版各跑一支確認過:
`ltx23_t2v` 768×512/97 幀 **225 秒**(487KB)、`ltx23_t2v_hq` 640×384→**1280×768** **285 秒**(790KB),
兩支都帶 AAC 音軌。**HQ 這 285 秒比 Python 版當初量的 617 秒快很多,是因為當時 ollama 佔著 2.2GB**
——同一件事的再一次印證。畫質對照:HQ 明顯乾淨,快速版同 prompt 會在主體上生怪東西(紙船上多一個
娃娃頭),要交付的成品建議直接走 HQ。見 [[workflowui-public-url]]。

⚠ 上面的速度只在 **GPU 空著**時成立(`ollama ps` 空、VRAM used ~571MiB)。被 ollama 完整佔住時
同一張卡會變成每步 350–400 秒,見 [[comfy-161-shared-machine-gpu]]——測速前一定要先確認。

`LTXAVTextEncoderLoader.device` 有 `default` / `cpu` 兩個選項。卡片用 `default`(那是實測跑出
91/137/183 秒的設定)。`cpu` 我試過但在機器被佔用時測的,**沒有有效對照**,別當成已驗證的優化。

相關:[[comfyui-161-upgrade-0816]] [[video-card-pattern-and-reactor-gap]] [[workflowui-vision]]
