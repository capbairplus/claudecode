---
name: workflowui-minimax-h3-cards
description: "MiniMax H3(海螺 3.0)兩張卡在 .161 上的完整落地結果——模型檔、實測秒數、turbo LoRA 可用、以及踩到的檔名前綴雷"
metadata:
  type: project
  originSessionId: current
  modified: 2026-08-17T20:10:00.000Z
---

**2026-08-17 完成 4 張卡**(同一個 group `minimax_h3_video`),全部對真 .161 端對端驗證過
(送出→生成→寫檔→`_meta` 存 prompt/workflow):`minimax_h3_t2v`(文字生影片)、`minimax_h3_i2v`
(圖生影片)、`minimax_h3_flf2v`(首尾幀 A→B)、`minimax_h3_r2v`(兩張參考圖)。

**⚠ 兩套都要放**(2026-08-18 補):四張卡一開始只加在 Python 版(8899),使用者去看公開網址
`https://capbairplus.duckdns.org/comfyuicard/` 發現沒有——那是 **C# 版**(8900)。已補上:把
`workflow_templates\minimax_h3_*\` 四個資料夾複製到 `C:\wordpresscb\workflowui-csharp-poc\
workflow_templates\` **和** `bin\Debug\net8.0-windows\workflow_templates\`(服務實際讀的是 build
輸出目錄)。**只複製 JSON 不用 rebuild、也不用重啟服務**——`ManifestLoader.LoadCards()` 每次請求
都重掃目錄,複製完立刻從 35 張變 39 張。C# 版已用 `/api/generate` 實測生成成功(227 秒,同一支
t2v 卡)。C# 的 manifest 模型完全吃得下這幾張卡:`category` 是純字串(沒有 enum 限制)、
`FieldType` 有 select/image/number/integer/seed/textarea/text、`SelectOption` 也是 `{value,label}`、
`group`/`group_label` 在 `/api/cards/{id}` detail 端點回傳(list 端點對所有卡都不回傳 group,正常)。
另外 `ltx23_t2v` / `ltx23_t2v_hq` **到現在還是只有 Python 版有**,C# 版沒移植。詳見 [[workflowui-public-url]]。

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

R2V 另外補抓了 `minimax_h3_ref2va_pruned_int8_convrot.safetensors`(19.53 GiB)+
`minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors`(1.82 GiB)。

**autogrow 動態輸入在 API 格式怎麼寫**(R2V 卡的關鍵):`MiniMaxH3ReferenceToVideo` 的參考素材是
`COMFY_AUTOGROW_V3` 型別(`ref_images` 最多 9、`ref_videos`/`ref_audios` 各 3),在 API graph 裡的
input key 是**點號展開的名字**:`ref_images.ref_image_0`、`ref_images.ref_image_1`……。實測 ComfyUI
的 `/prompt` 吃這種 key,manifest 直接把 `input_key` 寫成這串就行,workflow_engine 不用改。

**⚠ 卡片固定吃兩張參考圖**,因為 WorkflowUI **沒有「選填媒體欄位」的機制**:引擎不會在欄位留空時把
對應的 `LoadImage` 節點剪掉(`workflow_engine` 只有 `_set_input`,沒有 prune),留著就會因為預設檔名
不存在而驗證失敗。要做「1~9 張可變數量參考圖」得先在後端加「空值時剪掉該節點與引用它的 input」。

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
| flf2v 首尾幀(4 步,同時在下載 19.5GB) | 180 秒 |
| r2v 兩張參考圖(4 步,含冷載入 ref2va) | 315 秒 |
| **209 幀(8.7 秒)**、864×480 | 234 秒(幀數 1.7× → 時間 2.1×) |
| **1344×768**、124 幀 | 376 秒(像素 2.5× → 時間 3.4×) |
| r2v 熱快取、參考圖 1344×768、`match` | 133 秒 |

**時間大致跟「像素 × 幀數」成正比但略超線性**;批次 2 支跑完 435 秒(每支偏高是因為第一支冷載入 +
chavi 同時在用 GPU)。

**`ref_image_size` 的 `max` 到底慢多少,取決於參考圖本身多大**(它只縮不放大,上限 2048 短邊)。
同樣輸出 864×480:參考圖 1344×768 時 max 143 秒 vs match 133 秒(+8%);參考圖 3584×2048 時
max 要 **345 秒 = 2.6 倍**;參考圖只有 864×480 時兩者根本沒差(第一次測時我就是餵小圖,結果
「max 比 match 快」——那是模型換載入的假訊號,不是設定的效果)。節點 tooltip 的「several times
slower」只有在真的餵大圖時才成立。

**批次路徑已驗證**(`repeat` + `text_batch_row_key`):`_meta` 裡的 workflow 顯示 seed 1000→1001
逐支遞增、每行 prompt 各自寫進對應 job、檔名前綴照 row 的 label 分開。

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

**踩到的另一件事:.161 的 ComfyUI 會自己死掉**(2026-08-17 22:40–22:53 之間,不是被我送的工作弄死的
——當時連 upload 都還沒成功)。徵狀是 8188 沒在 listening、`tasklist` 只剩幾個幾百 KB 的 python.exe。
Session 0 沒有 console,**死掉不會留任何 log**,只能從 port + 進程大小判斷。復原就照
[[comfyui-161-upgrade-0816]] 的安全方式:`schtasks /Run /TN comfyui`(不要用 ReComfyui)。
**啟動要等約 200 秒**(載 custom nodes),期間 port 不會 listen、進程記憶體會從 ~100MB 長到 1.6GB,
別以為它掛了就重跑一次。

相關:[[workflowui-ltx23-card]] [[comfyui-161-upgrade-0816]] [[video-card-pattern-and-reactor-gap]] [[workflowui-vision]]
