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

**2026-09-03 補上 `minimax_h3_v2v`(參考影片生影片)**——先前四張卡全部只接 `ref_images`,
`MiniMaxH3ReferenceToVideo` 還有三組輸入沒人用:`ref_videos`(最多 3,IMAGE 幀批次)、
`ref_video_audios`、`ref_audios`。v2v 就是把 `VHS_LoadVideo`(`force_rate=24` 對齊模型)的 IMAGE 輸出
接到 `ref_videos.ref_video_0`,prompt 裡用 `<Video 1>` 指涉,其餘沿用已驗證的 r2v graph
(ref2va 模型 + ref2v turbo LoRA,零額外下載)。**實測效果正確:身份/外觀來自參考影片、動作來自
prompt**(拿貓在窗台的影片當參考,prompt 要牠跳到地板,輸出就是同一隻三花貓跳下窗台)。

**參考影片的成本(864×480 輸出、4 步、熱快取)**:參考 48 幀 **255 秒**、120 幀 **315 秒**,
**每多 1 幀約 +0.83 秒**(對照:同 graph 用 2 張參考圖是 150 秒)。所以卡片把 `frame_load_cap`
開成欄位、預設 48(2 秒),照斜率推估 360 幀(15 秒)約 8–9 分鐘。
**音訊也接了(2026-09-03 同日補),但踩了兩個雷才成立**:

1. **`VHS_LoadVideo` 的 audio 輸出一接上,遇到無音軌影片就整個炸**
   (`VHS failed to extract audio from ...`)——它是被連線才去抽音軌,抽不到就丟例外。
   有音軌 195 秒成功、無音軌直接 error,實測確認。
2. **想用 `PrimitiveString` 當中介把同一個檔名餵給兩個載入節點,會在驗證階段就被擋**:
   `'NoneType' object has no attribute 'endswith'`。**影片/檔案這種 COMBO 輸入不能吃連線**,
   必須是字面字串——跟 LTX 卡那個 `PrimitiveInt` 餵 INT 的手法不一樣,別以為 Primitive 中介萬用。

**最後解法:整條改走核心節點**,檔名就只出現在一個節點上,欄位綁得住:
`LoadVideo(file) → GetVideoComponents → images → ImageFromBatch(batch_index=跳過, length=幀數上限)
→ ref_videos.ref_video_0`,音訊 `GetVideoComponents.audio → ref_video_audios.ref_video_audio_0`。
**核心 `GetVideoComponents` 對無音軌影片是回傳 `audio=None` 而不是丟例外,而 H3 節點吃得下 None**
——所以有聲/無聲的參考片都能跑(實測 225 秒 / 210 秒,兩者輸出都帶 AAC 音軌)。

**代價**:核心節點沒有 VHS 的 `force_rate`,**不會自動轉幀率**,所以參考片最好本身就是 24fps
(模型預期 24fps 參考幀);`ImageFromBatch` 取代了 `frame_load_cap`/`skip_first_frames`。

**多支參考影片 + 獨立參考音訊(2026-09-03 再擴充)**:v2v 現在是 1~3 支參考影片 + 最多 3 段獨立音訊。

**關鍵是後端早就有剪枝機制了,別自己造輪子**——別的 session 做 `minimax_h3_r2v_multi` 時已經在
C# 的 `Services/WorkflowEngine.cs` 加了:
- manifest 欄位的 `prune_when_empty: true` → 欄位留空就把它綁的節點從 graph 剪掉,
  並清掉其他節點指向它的斷鏈(`PruneNodes`)
- `CompactAutogrowKeys()` → 剪完把 `ref_images.ref_image_N` 這類 autogrow 編號重排成 0..n-1,
  否則中間留洞會讓節點從 0 走到洞就停,後面的槽悄悄消失

**但剪枝只剪「欄位綁的那一個節點」,不會連鎖剪下游**。我的主影片槽是 3 個節點的鏈
(`LoadVideo → GetVideoComponents → ImageFromBatch`),剪掉第一個會讓後面變成缺必要輸入。
解法是**額外的影片槽改用單節點的 `VHS_LoadVideo`(只接幀、不接音訊)**——先前那個「無音軌影片會炸」
只在音訊輸出被接上時發生,**只取幀時無音軌影片實測可以過**。獨立音訊槽用 `LoadAudio`(也是單節點)。
代價:第 2、3 支影片固定取前 48 幀、不吃它們的音軌,只有第 1 支的音軌會當條件。

**實測(864×480 / 5 秒 / 4 步)**:
| 情況 | 耗時 | 結果 |
|---|---|---|
| 只有影片 1(5 個選填槽全空) | 330 秒(含冷載入) | ✅ `_meta` 確認節點 30/31/32/33/34 全被剪掉、沒有斷鏈 |
| 影片 1 + 影片 2(96 幀參考) | 405 秒 | ✅ **兩支參考確實被組合**:`<Video 1>` 的貓走在 `<Video 2>` 的海灘上 |
| 影片 1 + 獨立音訊 1(`LoadAudio` → `ref_audios.ref_audio_0`) | 240 秒 | ✅ `_meta` 確認只留節點 32、30/31/33/34 被剪 |

**⚠ 這三個測試被打斷了三次,但不是我的 graph 有問題**:當天 ComfyUI 四度中斷,查證後確認
**不是當機**——Windows 事件記錄沒有任何 python 的 Application Error/WER(只有前一天一筆記憶體洩漏
診斷)、記憶體剩 35GB/63.8GB、排程工作 `comfyui` 的 LastRunTime 停在早上 08:58 沒再執行過,
但進程每次都自己回來。最像的解釋是 **ComfyUI Manager 的內建自我重啟**(裝/更新 custom node 會觸發),
而 `custom_nodes\TTS-Audio-Suite` 當天 09:02 才被動過,顯示有別的 session 在弄音訊節點。
**排查「ComfyUI 又掛了」時,先分清楚「當機」還是「被重啟」:看 Windows 事件記錄有沒有 WER、
排程工作 LastRunTime 有沒有更新、以及 custom_nodes 有沒有剛被動過。**

**⚠ `group_order` 要先查別人用了什麼**:我一開始給 v2v 填 5,結果撞到別的 session 做的
`minimax_h3_r2v_multi`(也是 5),改成 6。這組現在是 t2v(1)→ i2v(2)→ flf2v(3)→ r2v(4)→
r2v_multi(5)→ v2v(6)。

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
