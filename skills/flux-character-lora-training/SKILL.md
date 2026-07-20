---
name: flux-character-lora-training
description: >
  用相片訓練 Flux 人物角色 LoRA 的完整流程:用 Qwen Edit 從 1 張參考圖鎖臉擴增
  素材(多角度/表情/髮型/全身/服裝/場景)+ InsightFace 自動臉一致性把關 →
  精簡 caption → 在 kohya(.161)flux_train_network 訓練 → ComfyUI 生圖測試、
  挑 epoch、調強度 → 收尾與已知限制。當使用者想「訓練/製作某角色的 LoRA」
  「用照片練人物模型」「幫某角色做 LoRA」「把周以諾/蘇若冰那套流程套到別的角色」
  「角色只有幾張圖怎麼擴增素材」「用 Qwen edit 生多角度/表情/全身變體」「臉一致性
  把關/剔除飄掉的圖」,或在 .161 / kohya / ComfyUI 上做 Flux 人物模型、討論觸發詞/
  epoch/LoRA 強度/臉不像怎麼救時,務必使用本 skill——即使他沒明講「skill」。
  一般打標流程可搭 comfyui-lora-dataset-prep;本 skill 專注擴增→把關→訓練→測試→交付的完整鏈路。
---

# Flux 人物角色 LoRA 訓練流程

把「一疊某角色的相片」變成一顆可用的 Flux 角色 LoRA。以《漂流者》周以諾專案為
參考實作(成品 = v2 ep4);同一套可複用到其他角色。

## 核心心法(先讀,這決定成敗)

- **像不像 = caption + 資料集,不是調參數**。最常見失敗是「臉往平均臉收斂、不夠像」。
  根因幾乎都是:①caption 把固定長相寫死 ②素材不是同一張臉。調 strength / epoch 救不了。
- **精簡 caption 是關鍵**:只留 `觸發詞 + 會變的元素`(服裝/姿勢/視角/表情/背景),
  **拿掉固定長相**(髮型、髮色、臉型、膚質、「same character identity」等)。
  這樣長相才會被綁進觸發詞,而不是被一堆詞稀釋。
- **臉要夠大才守得住身分**:全身遠景臉小 → 不像是必然。測試/成品盡量近景、臉為主。
- **три者難兼得**:精準的臉 + 自然動態 + 精準場景。動態/寫實場景要降 strength,
  必要時改「參考圖 img2img + PuLID 換臉」(見 §5)。

## 環境(參考:.161 那台)

- 訓練機 `.161`(RTX 4060 Ti 16GB):`D:\kohya_ss`,`sd-scripts\flux_train_network.py`,
  venv `D:\kohya_ss\venv\Scripts\python.exe`。SSH:
  `ssh -i C:\Users\capbair\.ssh\id_ed25519_161 solisadmin@192.168.1.161`。
- Flux 四件套(在 ComfyUI portable 內):
  `...\diffusion_models\flux\flux1-dev.safetensors`(23.8GB unet)、`clip_l.safetensors`、
  `...\clip\flux1\t5xxl_fp16.safetensors`(9.8GB)、`...\vae\ae.safetensors`。
- 生圖 ComfyUI:`http://192.168.1.161:8188`。

## 流程總覽

0. 選定基準臉(大頭 + 全身各一);素材不足 → 用 **Qwen Edit 鎖臉擴增**出多角度/表情/髮型/全身/場景(§1.5)
1. **自動臉一致性把關**剔除飄的(§1.6)→ 篩選 + 精簡 caption(§1)
2. 排 kohya dataset.toml + train.bat,清 GPU,SYSTEM 排程 detached 開訓
3. ComfyUI API 生圖測試,挑 epoch、調 strength
4. 收尾:選成品、備份、寫 README
5. 若「不夠像 / 動態場景難」→ 進階救援(降強度 / 參考圖 img2img / PuLID)

---

## 每角色 RUNBOOK(反覆套用;套一個新角色只換 3 樣:觸發詞、2 張參考圖、輸出路徑)

> 蘇若冰驗證後即為標準流程。腳本範本全在 `su_ruobing\_scripts\`,只改頂端 `REF / OUT / CHARACTER_NAME / 觸發詞`。

**A. 前置(不吃 GPU)**
1. 觸發詞:罕見 ASCII(如 `lin_xiao`)。
2. 挑 **2 張基準圖**:①乾淨**正臉大頭**(臉錨,避開透明底/首飾/浮水印)②**同套裝全身**;存 `reference\`。
   `.jfif→.png`、清浮水印。
3. 建資料夾骨架(仿 su_ruobing)。

**B. 生「身分訓練」素材(Qwen Edit @.161,ComfyUI 要開;每張約 10–15s)**
4. 臉:`su_face_gen.py`(REF=大頭)→ 15–29 張**多角度 neutral/溫和表情**近照。
5. 全身:`su_body_turntable.py`(REF=全身)→ **整圈轉台、同套裝、neutral** ~18–40 張。
   🚨 **身分訓練集只放這兩種(多角度 neutral)。** `su_expr_qwen.py`(表情)、`su_hair_qwen.py`(髮型)、
   `su_body_qwen.py`(場景/服裝)產的是 **「生圖用」素材——訓練好之後拿 LoRA 去生,不要進訓練集**(會讓臉飄)。
6. 把關:`gate_*.py` 對基準臉 cosine,剔飄的(臉特寫 <~0.6、全身 <~0.45),看接觸表複核。

**C. 訓練(.161 kohya)**
7. **細 caption**(標滿視角/表情/衣服/背景,照周寫法;別太省)。
8. `dataset.toml`(face×6 / body×2、**正斜線路徑**)+ train bat(複製 `train_su.bat` 改路徑/`output_name`)。
9. 清 GPU(停 ComfyUI/llama)→ **SYSTEM 排程 detached** 開訓 → 監看 log。

**D. 測試交付**
10. epoch 測試(固定 seed、臉特寫逐 epoch)→ 挑 ep3–4 → 備份全 checkpoint 到 G:、生圖機留一顆成品 → 寫 README。

**順序**:先素材最全的角色(如 lin_xiao)驗證整條 runbook,再其餘。

---

## 1. 資料集與精簡 caption

- **先定「決定版基準臉」**一張(所有篩選、換臉都對它)。存 `reference\<角色>_REF.png`。
- 資料集:**臉部特寫**(身分主力)+ **全身/多角度**(身形/姿勢);全部 PNG、~768、
  每張同名 `.txt` caption 配對齊。剔除「不是這張臉」的、有浮水印/雜訊的。
  **單/少圖 → 用 Qwen Edit 鎖臉擴增出多角度/表情/髮型/全身/場景(見 §1.5),再把關(§1.6)。**
  (WD14/Florence 打標等一般資料集流程 → 搭 skill `comfyui-lora-dataset-prep`。)
- **建議張數**(品質與一致性 > 數量):甜蜜點約 **30–60 張**;最低 ~15–25 張也能練出可用。
  **周以諾 v2 實測配方(成品)= 臉 29(多角度 neutral)+ 全身 90(整圈轉台同套裝),face×6 / body×2。**
  注意是**全身多、但都是一致轉台**——不是雜圖。全身圖臉小、身分訊號弱,靠「同一套裝、多角度、量大」把身分從各面釘牢;
  別丟一堆場景/服裝各異的雜全身(那是生圖素材)。素材不足 → 先用 §1.5 擴增補足再練。
- **caption 要標滿變動元素**(周的寫法):連臉照都標衣服+背景,例:
  `zhou_yinuo, front face close-up, neutral expression, white knit top, delicate necklace, plain gray background`。
  把衣服/背景/視角/表情全標出來,觸發詞才只剩「臉」;標太省(如只寫 `face close-up, front view`)= 衣服背景被吸進觸發詞、身分被稀釋(蘇 v1 的錯)。
- **資料集踩雷(進訓練前務必處理)**:
  - `.jfif` / 網頁存檔格式 kohya/ComfyUI **多半不吃 → 先轉 `.png`/`.jpg`**。
  - **生成器浮水印**(如右下 ✦ 星芒)不清會被 LoRA 學進去 → 先清掉/裁掉。
  - **來源混合**(AI 圖 + 實拍)務必是**同一張臉**,否則身分漂移、學成平均臉。
  - **ASCII 路徑 + `PYTHONUTF8=1`**:cp950 系統跑中文路徑/打標會崩;路徑用英文。
- **重打精簡 caption**(關鍵步驟):
  - 保留:`<觸發詞>`(罕見、專屬,如 `zhou_yinuo`)+ 視角/表情/服裝/背景/框景。
  - 砍掉:固定長相描述(髮型/髮色/瀏海/臉型/膚質/「young X woman」「same identity」
    「consistent face」「identity reference portrait」等)。
  - 原檔別動,精簡集另存新資料夾。
  - 範例:
    - 前:`zhou_yinuo, young Taiwanese woman, natural black wavy hair with bangs, consistent face, ..., white knit top, plain gray background`
    - 後:`zhou_yinuo, front face close-up, soft smile, white knit top, plain gray background`

## 1.5 用 Qwen Image Edit 從參考圖擴增素材(周/蘇都走這條,推薦)

素材不足(常見:某角色只有 1–9 張)時,**別拿別的工具亂生全身圖**——沒鎖臉會飄成別人
(蘇踩過:外部生的 54 張有 19 張 cosine<0.45、含明顯異臉,整批作廢重生)。正解是用
**Qwen Image Edit 2511(.161)以參考圖鎖臉**擴增:身分穩、速度快(4 步,一張約 10–15s)。

- 🚨 **鐵律:身分訓練素材 ≠ 生圖素材,絕不可混。**(蘇 v1 就是混了才退步、比周差一截)
  - **進 LoRA 身分訓練的,只放:多角度 + neutral/溫和表情的乾淨臉 + 同套裝整圈轉台的多角度全身。**
    周 v2 實測就是這樣:臉 = front/±45/profile 全 neutral(29 張);全身 = front/back/left/right/three-quarter/side
    轉一圈同套裝 neutral(90 張)。**激烈表情=0、濕髮亂髮=0。** 這才練得像。
  - **激烈表情(哭喊/痛苦/驚恐)、濕髮/亂髮/落難、場景服裝大變**:這些是**成品生圖階段**才用的素材,
    **不要放進身分訓練集**——臉會變形、把學到的身分往平均臉拉。要生那些,是「訓練好之後拿 LoRA 去生」,不是拿來訓練。
- **兩種參考圖 → 兩種用途(分開)**:
  - 參考 = **大頭照**(臉大) → 【身分訓練】多角度 neutral 近照(±15/30/45/profile) ‖ 【生圖用,不進訓練】表情、髮型/打光狀態
  - 參考 = **全身圖**(有身形) → 【身分訓練】同套裝整圈轉台多角度全身 ‖ 【生圖用,不進訓練】服裝/場景/姿勢
- **同一條工作流**(API graph;範例腳本 + JSON 見 `su_ruobing\_scripts\`,可直接改 REF/OUT/SHOTS 重跑):
  `UNETLoader(qwen_image_edit_2511_fp8)→LoraLoaderModelOnly(Lightning-4steps 1.0)→`
  `LoraLoaderModelOnly(multiple-angles-lora 0.45–0.55)→ModelSamplingAuraFlow(shift 5.0)→CFGNorm(1.0)`;
  `CLIPLoader(qwen_2.5_vl_7b_fp8,type qwen_image)`;`VAELoader(qwen_image_lowgpu_vae)`;
  `LoadImage→QwenEditConfigPreparer(ref_longest_edge 1280,pad;vl_target_size 384)`;
  `QwenMultiangleCameraNode(horizontal_angle,zoom)→StringConcatenate(prompt+相機提示)→`
  `TextEncodeQwenImageEditPlusCustom_lrzjason(configs,instruction)→`
  `FluxKontextMultiReferenceLatentMethod(index_timestep_zero)` 正 /(`ConditioningZeroOut`→同法)負 →
  `KSampler(steps 4,cfg 1.0,euler,simple,denoise 1.0)→VAEDecode→SaveImage`。
- **只換三樣**:參考圖、prompt(共同鎖定句「exact same person, same face/proportions…」+ 變動文字 + instruction)、下列參數:

  | 用途 | 參考 | multi-angle LoRA | zoom | horizontal_angle |
  |---|---|---|---|---|
  | 表情 / 髮型 | 大頭照 | 0.45–0.55 | 2.7(頭肩) | 0 |
  | 多角度 | 大頭照 | 0.55 | 2.7 | 0 / ±15 / ±30 / ±45(左 = 360−x) |
  | 全身 / 場景 | 全身圖 | 0.50 | 1.0(全身)/ 1.8(半身) | 0 / ±30 / 180(背面) |

- **Qwen 能 / 不能**:穩換角度、框景、服裝、場景、打光、髮型狀態、表情;坐/蹲/背面也多半生得出。
  極端表情(張大嘴哭喊)臉會略變、把關分數自然較低,肉眼仍是本人。45° 以上、強風髮遮臉時較易飄。
- **prompt 雷**:哭泣別寫「eyes red」(會生血淚)→ 改「clear glistening tears」。島嶼/濕衣類保持得體、完整覆蓋、不性化。
- instruction 要明講可改什麼(「You MAY change clothing/scene/framing…」)、鎖什麼(「Do NOT change facial identity or body type」),否則它會連臉一起改或當作「沒給新圖」用舊的。

## 1.6 自動臉一致性把關(擴增圖 / 外部素材,進資料集前都要跑)

用 **InsightFace 對基準臉算 cosine**、剔除飄掉的。**在 .161 的 ComfyUI python 跑**(內建 insightface;
本機 python 常沒有,別在本機硬跑):`D:\ComfyUI_windows_portable\python_embeded\python.exe`,
`FaceAnalysis(name="buffalo_l" 或 "antelopev2", providers=["CPUExecutionProvider"])`,取**面積最大**那張臉的
`normed_embedding`,與基準臉做內積。門檻約 **0.45**。範例腳本 `su_ruobing\_scripts\gate_*.py`。

- **臉大小會壓分數**:頭肩特寫 0.53–0.90;全身臉小 0.45–0.65 屬正常 → **別用同一絕對門檻硬砍全身**。
  看「整批一致、有沒有明顯異臉」比看絕對值重要;有疑慮就人工看接觸表複核。
- **背面圖無臉分**(偵測不到臉)屬正常 → 保留(背面對資料集有價值)。
- 圖在別機 / NAS 存取不到 → **scp 到 .161 本機**再跑,或透過 localhost `http://127.0.0.1:8188/view` 抓
  ComfyUI 輸出(繞過檔案系統)。
- 每批生完固定產出:`manifest.json`(逐圖 prompt/seed)、`_contact_*.png`(接觸表)、`gating_report.txt`。

## 2. 在 .161 訓練(kohya flux_train_network)

**dataset.toml**(用 num_repeats,不用 N_ 資料夾複製檔;臉加重):
> ⚠️ **路徑用正斜線** `D:/lora_train/...`。用反斜線容易踩雷:heredoc/某些寫檔會把 `\\` 折成單 `\`,
> TOML 讀到 `\l`/`\s` 會 `Reserved escape sequence used` 直接崩(訓練啟動即失敗)。正斜線 kohya 照吃。
```toml
[general]
caption_extension = ".txt"
shuffle_caption = false
keep_tokens = 1
[[datasets]]
resolution = [768, 768]
enable_bucket = true
min_bucket_reso = 512
max_bucket_reso = 1024
bucket_reso_steps = 64
  [[datasets.subsets]]
  image_dir = "D:\\lora_train\\drifter\\<角色>\\body"
  num_repeats = 2
  [[datasets.subsets]]
  image_dir = "D:\\lora_train\\drifter\\<角色>\\face"
  num_repeats = 6
```

**train.bat**(可行參數;`train_zhou_yinuo_flux768_v2.bat` 為範本):
關鍵旗標——`--network_module networks.lora_flux --network_dim 16 --network_alpha 16
--network_train_unet_only`(**只練 U-Net、不練 CLIP-L**,身分較純)
`--optimizer_type adamw8bit --learning_rate 1e-4 --lr_scheduler constant`
`--fp8_base --gradient_checkpointing --sdpa --cache_latents(_to_disk)
--cache_text_encoder_outputs(_to_disk)`
`--mixed_precision bf16 --save_precision bf16 --guidance_scale 1.0
--timestep_sampling shift --discrete_flow_shift 3.1582 --model_prediction_type raw
--loss_type l2 --t5xxl_max_token_length 512`
`--max_train_epochs 6 --save_every_n_epochs 1`(**每 epoch 存檔,之後挑**)
底模/文字編碼/VAE 指到上面四件套;輸出 `--output_name <角色>_flux768_v2`,log 導到檔案。
速度約 7–8 s/it,~5 小時。

**開訓要點(踩過的雷)**:
- **先清 GPU**:.161 常有 ComfyUI / `llama-server.exe` / 別人的訓練佔滿 VRAM。開訓前
  `nvidia-smi` 確認,VRAM 被佔就會**每張換頁重載 → 龜速(9 分/張)**。用 `taskkill` 停掉
  佔卡的行程(訓練佔卡別亂砍,先問使用者)。
- **可靠啟動 = SYSTEM 排程 detached**(不是 `schtasks /run` 預設帳號——那在非互動 SSH
  下會回「成功」卻不執行,Last Result 267011=SCHED_S_TASK_HAS_NOT_RUN,無 log 無快取)。
  正解:
  ```
  schtasks /create /f /tn <task> /ru SYSTEM /rl HIGHEST /sc once /st 23:59 /tr "<train.bat>"
  schtasks /run /tn <task>
  ```
  Session 0 可跑 CUDA、免登入會話、SSH 斷不影響。開訓後可能因載入 33GB 模型 RAM 壓力大、
  SSH 一度被 RST(ping/banner 正常),稍等會恢復。
- 監看:讀 `logs\train_console.log` 尾段看 `steps: x% ... s/it`;log 裡的
  triton 未裝 / git dubious ownership / tensorflow 噪音都無害。

## 3. ComfyUI 生圖測試(挑 epoch、調強度)

- 把各 epoch checkpoint 複製到 ComfyUI `models\loras\`(或指路徑)。
- 用 ComfyUI HTTP API 生圖(**別靠 GUI**,批次快):`POST /prompt`(送 API graph)→
  輪詢 `GET /history/<id>` → 抓 `GET /view?filename=..&type=output`。
  模型檔名要從 `/object_info` 抓精確字串(含子資料夾反斜線,如
  `flux\flux1-dev.safetensors`、`flux1\t5xxl_fp16.safetensors`,別手打)。
  原生 Flux dev 節點鏈:`UNETLoader(fp8_e4m3fn)→LoraLoaderModelOnly→` +
  `DualCLIPLoader(clip_l+t5xxl_fp16,type=flux)→CLIPTextEncode→FluxGuidance(3.5)` +
  `VAELoader(ae)`;`SamplerCustomAdvanced`(euler/simple、20–24 步、denoise 1.0)。
- **挑 epoch**:固定 seed、用**臉部特寫** prompt 逐 epoch 比對。**epoch 3–4 常是好用區間**;
  太後面(final)會過度收斂變不像。挑「像且不僵」的當成品。
- **調 strength(LoRA 強度)**:典雅/定裝/肖像 = **1.0**(最像);寫實/濕髒/動態 = **0.65–0.85**
  (讓底模畫得出質感,臉略鬆但值得)。
- 生圖流程/連結給使用者的慣例:大批圖用**單一背景收集器**默默收、全好才通知;
  給檔案用純路徑;要看圖可把圖 upload 成 ComfyUI input 用 `/view` 給 HTTP 連結。

## 4. 收尾與交付

- 選定成品 epoch(如 v2 ep4),另存清楚檔名 `<角色>_FINAL_v2ep4.safetensors`。
- 備份全部 checkpoint 到專案 G:;生圖機 loras 只留成品一顆(乾淨)。
- 寫 `README_<角色>_lora.md`:成品是哪顆、觸發詞、底模、建議強度、訓練摘要、
  v1↔v2 差異、檔案位置、已知限制。(範本見周以諾 `README_zhou_yinuo_lora.md`。)

## 5. 進階:不夠像 / 動態場景救援

- **一般不夠像**:先確認基準臉一致 → 精簡 caption 重練(§1)才是根治。調 strength/epoch 只是微調。
- **動態/濕/髒場景像不出來**(棚拍 LoRA 會把人洗乾淨):降 strength 到 0.6–0.65 +
  提示詞重壓「濕透滴水/斜暴雨/泥污/狼狽/環境元素」+ 姿勢寫具體。
- **要精準複刻某構圖或某服裝**:純文字凹不出來 → 給**參考圖 img2img**(denoise ~0.5 保留構圖)。
- **要參考圖場景 + 精準的臉**:**PuLID-Flux 換臉**(.161 有裝):`PulidFluxModelLoader`
  (`pulid_flux_v0.9.0.safetensors`)+ `PulidFluxEvaClipLoader` + `PulidFluxInsightFaceLoader(CUDA)`
  + `ApplyPulidFlux(image=基準臉, weight~0.7–0.9)` 接在 flux1-dev 上;img2img 底(denoise ~0.45–0.5)
  保住原姿勢/表情、PuLID 把臉換成角色。LoadImage 讀不到檔時用 ComfyUI `/upload/image` 上傳。
- **冷門特定歷史服飾**(如清朝旗裝):Flux 純文字畫不準、也少對版 Flux LoRA → 用參考圖 img2img,
  或找/裝對版 LoRA;民國旗袍、古希臘等常見題材反而純文字就很好。

## 已知限制(誠實告知使用者)

- 極小/遠景臉會失真;人在水裡(游泳/泡水)Flux 易崩(讓身體多在水面上);
  單一參考臉 + 混來源素材 → 只能逼近不能 100% 複刻。
