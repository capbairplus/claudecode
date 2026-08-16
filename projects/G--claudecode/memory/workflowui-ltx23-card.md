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

**還沒做**:第二階段 spatial upscale(`ltx-2.3-spatial-upscaler-x2-1.1.safetensors`,約 1GB,還沒下載)。

相關:[[comfyui-161-upgrade-0816]] [[video-card-pattern-and-reactor-gap]] [[workflowui-vision]]
