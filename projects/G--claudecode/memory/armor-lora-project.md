---
name: armor-lora-project
description: 用《畫說中國歷代甲冑》掃描頁訓練甲冑風格 LoRA 的專案狀態與決策
metadata: 
  node_type: memory
  type: project
  originSessionId: c09ee9b7-bc94-4be4-82d5-4b3bc9170e3d
---

使用者要用書《畫說中國歷代甲冑》(陳大威, 2017) 的掃描頁訓練一個**甲冑插畫風格 LoRA**。專案於 2026-06-26 啟動。

**素材與路徑:**
- 原始: `F:\book\war\中西甲胄书籍合集\畫說中國歷代甲冑\` — 257 張 PDF 匯出書頁,檔名 `…_頁面_NNN.jpg`,皆 ≥1024。
- 工作區(2026-07-02 已搬到 G): `G:\claudecode\armor-lora_2026-06-26\` — 依朝代分 15 個資料夾 (`01_shang`…`15_qing`) + `00_unused`。(原在 `F:\book\war\中西甲胄书籍合集\畫說中國歷代甲冑 - LORA\`,已整包搬移+刪來源;F 槽尚有失效捷徑 `…LORA - 捷徑.lnk` 可刪。)遵 [[workspace-convention-gclaudecode]] 命名。
- **頁碼偏移: 檔名編號 = 書內頁碼 + 8**(已驗證)。目錄在 `頁面_007`/`頁面_008`。

**朝代→檔案範圍**(共 246 張內容頁): shang 009-018, western_zhou 019-027, eastern_zhou 028-040, qin 041-060, han 061-079, wei_jin 080-088, northern_southern 089-102, sui 103-111, tang 112-139, five_dynasties 140-149, song 150-172, liao_jin_xixia 173-185, yuan 186-205, ming 206-231, qing 232-254。

**決策:**
- 練**單一風格 LoRA**(非每朝代一個);朝代差異靠 caption tag(`tang dynasty` 等),不靠資料夾。
- 書頁需裁切隔離插圖;多圖頁要拆成「一圖一檔」;殘留引線標註**採「打標容忍」**(`.txt` 加 `text`,生圖負面詞壓制),練完測試再決定要不要回頭清。
- 環境只有 Python 3.14 + Pillow + numpy(無 scipy/cv2/OCR/torch)。裁圖用自寫 numpy 連通元件 + 形態學開運算(去引線)+ 重建(找回綁繩)+ 輪廓白底化。腳本在工作區 `_demo_crop.py` / `_batch_test.py`。

**進度(至 2026-06-26):** 分類完成 → 全 15 朝代批次裁切完成(`_crops\<朝代>\` 共 671 張草稿,含自動轉正 `_rot` + 白底化)→ 使用者決定**不篩選,全收** → WD14 打標完成。
- 打標用 `_wd14_tag.py`(使用者自寫,torch+transformers,SmilingWolf/wd-vit-tagger-v3,GPU)。模型快取在 `F:\book\war\models`。
- 修過兩個 bug:(1) tag 清單前面誤插 3 個 rating 假項目→標籤位移錯位,已移除;(2) 每句前面加觸發詞 **`cdw_armor`**。caption 格式 = `cdw_armor, <朝代>, <wd14 tags>`。
- WD14 是動漫模型,對甲冑有雜訊標(japanese_clothes/blue_hair 等),v1 先容忍。
- **環境實況:Python 3.14 已有 torch 2.12.1+cu126 (CUDA可用) + onnxruntime 1.27 + transformers 5.12 + huggingface_hub。** torch/IOPaint 精修環境「稍後再做」。

**SDXL 訓練(2026-06-26 啟動 v1):**
- 新裝 sd-scripts 在 `C:\sd-scripts`(venv Python 3.10 + torch 2.5.1+cu124)。舊的 `D:\sd\kohya_ss` 太舊(無 sdxl_train_network、torch 1.12),不能用。
- 底模 `sd_xl_base_1.0.safetensors`(在 D:\ComfyUI_windows_portable\...\checkpoints)。資料集複製到本機 `C:\armor_lora\img\1_cdw_armor\`(671 png+txt),輸出 `C:\armor_lora\model`。訓練腳本 `C:\armor_lora\train.ps1`。
- **本機 RTX 3060 12GB + 16GB RAM 記憶體很緊,踩雷紀錄(重要):** ① 不加 lowram → 載入吃滿系統 RAM → access violation 崩潰(RAM 只剩 5-7GB);② 加 lowram 但 1024 → VRAM OOM;③ 關鍵解法 = **使用者關掉瀏覽器等程式騰出 VRAM**,再用 `--lowram --full_bf16 --resolution 768 --max_bucket_reso 768`,VRAM 穩在 ~10GB;④ cp950 系統必須設 `PYTHONUTF8=1` 否則 log 中文字觸發 UnicodeEncodeError 崩潰;⑤ expandable_segments 在 Windows 不支援。
- v1 參數:network_dim 32/alpha 16, AdamW8bit, unet_lr 1e-4/te 5e-5, cosine, 4 epoch=2684 步, ~2s/it(約 1.5 小時), save_every_n_epochs 1。觸發詞 `cdw_armor`。

**SDXL v1 已完成並驗證**(2026-06-26):4 epoch 練好,ComfyUI 實測畫風/寫實真人/全身戰鬥/朝代切換/文字壓制皆 OK。最終版 `cdw_armor_sdxl_v1.safetensors` 已複製到本機 ComfyUI loras。說明檔 `C:\armor_lora\model\說明_cdw_armor_lora.txt`。寫實配方:寫實SDXL底模(helloworld)+ LoRA 0.5~0.7 + 寫實提示;全身要畫布 768x1344。

**Flux 訓練機 192.168.1.161(進行中):**
- **SSH 存取(得來不易,記法):** 該機 Windows、受 WSUS 管控(Add-WindowsCapability 裝 OpenSSH 失敗 0x8024001e)→ 改手動裝 Win32-OpenSSH GitHub 版到 `C:\Program Files\OpenSSH`。**關鍵:sshd 以 SYSTEM「服務」執行會在 KEX 重置(管控機),改以 solisadmin 身分用排程常駐才通**:排程名 `sshd_user` 跑 `sshd.exe -D`、AtStartup、RunLevel Highest。本機私鑰 `C:\Users\capbair\.ssh\id_ed25519_161`,連線 `ssh -i <key> solisadmin@192.168.1.161`。複雜遠端指令要「寫腳本→scp→遠端執行」避免巢狀引號。
- **.161 環境:** RTX 4060 Ti 16GB；Python 3.11 已有 torch 2.6.0+cu118 (CUDA)；`D:\kohya_ss\sd-scripts` 有 flux_train_network.py(支援 Flux);Flux 模型齊全在 `D:\ComfyUI_windows_portable\ComfyUI\models\`(flux1-dev.safetensors 22.7GB、flux1-dev-fp8 16GB 等);工作目錄建在 `E:\flux_lora`(E: 有 2.78TB)。
- 決策:① caption 用 Florence-2 重打成自然語言(671/671 完成,`D:\flux_lora\dataset` 圖+txt) ② 用現成 kohya-flux(D:\kohya_ss,torch 2.7)。
- **Flux v1 訓練完成(2026-06-26):** flux1-dev + fp8_base + t5xxl_fp16,768解析度,dim16/alpha16,lr1e-4,3 epoch=2013步,~3小時,avr_loss 0.24。輸出 `D:\flux_lora\output\flux_cdw_armor.safetensors`(+epoch1/2)。設定/腳本在 `D:\flux_lora\`(flux_train.ps1, dataset.toml)。
- **Flux 訓練可靠啟動法(踩雷後的解):** accelerate launch 在這台 cp950 系統會因 reader-thread UnicodeDecodeError 卡死/空log;前景 ssh 跑會被斷線(exit 255)殺掉。**正解 = 直接用 venv python 跑 flux_train_network.py(不經 accelerate)+ 用「SYSTEM 排程工作」detached 執行(`run_flux_task.ps1`,輸出導到 train_full.log)**,抗斷線。設 PYTHONUTF8=1。
- 生圖:LoRA 複製到 .161 `ComfyUI\models\loras`,從本機 POST 到 `http://192.168.1.161:8188`(可達)。Flux 工作流:UNETLoader(flux\flux1-dev, fp8_e4m3fn)+ DualCLIPLoader(clip_l + flux1\t5xxl_fp16, type flux)+ VAELoader(ae)+ LoraLoaderModelOnly + FluxGuidance(3.5)+ SamplerCustomAdvanced(euler/simple, 24步)+ EmptySD3LatentImage。腳本 `C:\armor_lora\gen_flux_dynasties.py`。

**Flux v1 問題與 v2 源頭修正(2026-06-26):** v1 生 15 朝代**長得都差不多、朝代不準**(秦不像秦)。根因:通用詞「qin dynasty」撞 Flux 先驗 + Florence 長句 caption 稀釋朝代訊號 + 無專屬觸發詞 → 15 朝代被平均成一個概念。**教訓:分概念風格 LoRA 的 caption 要「短+專屬罕見觸發詞」,長自然語言會害區分。** v2 修正:每朝代專屬觸發詞 `cdwqin/cdwtang/cdwming…` + 極簡 caption「<trigger>, ancient chinese armor」+ 分 15 朝代資料夾 + 平衡 repeats(`recaption_v2.py`→`dataset_v2`+`dataset_v2.toml`),重訓 dim32/2epoch→`flux_cdw_armor_v2`。生圖用 cdwXXX 觸發。

**(原)待辦:** v1 訓練完 → ComfyUI 測 + 負面詞壓制殘留文字/臉 → 不行再迭代(IOPaint 清圖、WD14 黑名單、篩選、或上 .161 4060 練更高解析度)。見 [[political-cartoon-creative-bar]] 無關。
