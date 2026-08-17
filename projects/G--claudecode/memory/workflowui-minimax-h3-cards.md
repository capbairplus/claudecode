---
name: workflowui-minimax-h3-cards
description: "MiniMax H3(海螺 3.0)兩張卡在 .161 上的完整落地結果——模型檔、實測秒數、turbo LoRA 可用、以及踩到的檔名前綴雷"
metadata:
  type: project
  originSessionId: current
  modified: 2026-08-17T20:10:00.000Z
---

**2026-08-17 完成 `minimax_h3_t2v` / `minimax_h3_i2v` 兩張卡**(group `minimax_h3_video`),都對真 .161
端對端驗證過(送出→生成→寫檔→`_meta` 存 prompt/workflow)。

**為什麼比 LTX 那次省事**:ComfyUI 0.33.1 已內建 `comfy_extras.nodes_minimax_h3`(`MiniMaxH3ImageToVideo`、
`MiniMaxH3ReferenceToVideo`、`EmptyMiniMaxH3LatentAV`、`ModelSamplingMiniMaxH3`),**不用裝任何 custom node**,
官方 template 也在:`video_minimax_h3_{t2v,i2v,r2v}.json`(本地權重)+ `api_minimax_h3_*`(雲端 API 版)。
t2v/i2v 的真正結構包在 subgraph `Image to Video (MiniMax H3)` 裡,要手動展開(同
[[comfyui-builtin-template-subgraph]] 的做法)。

**.161 上補的檔案**(HF `Comfy-Org/MiniMax-H3`,共約 44GB,下載約 28MB/s):
| 檔案 | 實際大小 | 位置 |
|---|---|---|
| `minimax_h3_fl2va_pruned_int8_convrot.safetensors` | 19.53 GiB | `models\diffusion_models\` |
| `qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors` | 14.61 GiB | `models\text_encoders\` |
| `minimax_h3_video_vae_fp16.safetensors` | 4.85 GiB | `models\vae\` |
| `minimax_h3_audio_vae_fp32.safetensors` | 0.56 GiB | `models\vae\` |
| `minimax_h3_fl2v_turbo_4step_v1.0_768p_comfyui_bf16.safetensors` | 1.82 GiB | `models\loras\` |

R2V(參考素材生影片)還要多抓 `ref2va_pruned_int8_convrot`(19.53 GiB),**還沒做**——manifest 的
「一欄位對一個 node input」對付「最多 9 圖 / 3 影片 / 3 音訊 + prompt 裡用 `<Picture i>` 標籤」很彆扭。

**NVFP4 在 Ada(4060 Ti, sm 8.9)可用**:ComfyUI log 是 `Found quantization metadata version 1` →
`Using mixed precision operations` → `Native ops: float8_e4m3fn, int8_tensorwise, asym_w4a8_int8,
convrot_w4a4, emulated ops: nvfp4, mxfp...`。**主模型的 int8_convrot 走原生 kernel、NVFP4 文字編碼器是
模擬執行**,但整段文字編碼只花 6 秒,所以不必改抓 27GB 的 int8 TE。

**實測(RTX 4060 Ti 16GB,864×480 / 124 幀 = 5.17 秒)**:
| 設定 | 耗時 |
|---|---|
| 20 步、無 LoRA(冷啟動) | 355 秒 |
| 20 步、無 LoRA(熱快取) | 346 秒 |
| **4 步 + turbo LoRA** | **110 秒** |
| 4 步 + turbo,走 WorkflowUI 後端(含寫檔) | 120 秒 |

**冷熱幾乎沒差(355 vs 346)**——H3 是 "prepared for dynamic VRAM loading"(TE staged 14956MB、
主模型 staged 19995MB),載入成本被攤掉,時間幾乎全在取樣。這跟 [[workflowui-ltx23-card]] 的
「模型被擠出快取要多付 2–3 分鐘」不一樣,H3 不需要為了避免換模型而硬湊批次。

**社群說「pruned 版套不了 turbo LoRA」是錯的**(至少 fl2va pruned + `fl2v_turbo_4step_v1.0_768p` 這組):
不但跑得動,4 步的畫面比 20 步**更銳利**,檔案大小也更大(718KB vs 547KB)。所以卡片預設就是 4 步 + LoRA 1.0。

**輸出格式**:`CreateVideo`(fps 24)→ `SaveVideo`,落在 history 的 **`images`** key、`animated: true`,
`routers/generate.py` 已經同時讀 `images`/`gifs`/`audio`,**後端一行都不用改**。成品是 h264 + **AAC
立體聲 32kHz**,音訊是模型原生同步生成的(prompt 尾巴加一句 `Audio: ...` 就能指定要什麼聲音)。

**⚠ 檔名前綴不要帶子資料夾**:我一開始照 ComfyUI 慣例把 `filename_prefix` 預設寫成 `video/minimax_h3_t2v`,
生成會成功但最後寫檔炸掉(`No such file or directory: ...\i2v_smoke\video\xxx.mp4`)——WorkflowUI 的輸出
寫檔器**不會自動建巢狀子目錄**。所有卡片的 label/prefix 都要是單層檔名。

**參數硬限制**:
- `length` 走 **17k+5** 網格(124≈5秒、141、158…),官方訓練範圍 **124–362**,低於 124 沒訓練過。
  節點會自動往上對齊。
- 寬高要 32 的倍數;原生短邊 768,`0.4MP`(864×480)是官方 template 的預設甜蜜點,1344×768 約 2.5 倍時間。
- i2v 卡沿用官方做法:`LoadImage → ImageScaleToTotalPixels(megapixels, resolution_steps=32) → GetImageSize`
  再把 width/height 餵給 `MiniMaxH3ImageToVideo`,所以卡片上是「像素量」欄位而不是寬高,長寬比自動跟原圖。

**授權**:H3 Community License **排除美/歐/英/韓**在地部署,台灣不在排除名單。

相關:[[workflowui-ltx23-card]] [[comfyui-161-upgrade-0816]] [[video-card-pattern-and-reactor-gap]] [[workflowui-vision]]
