---
name: drifter-lora-project
description: 「漂流者」小說 6 角色的 LoRA 訓練專案:位置、現況、交接文件
metadata:
  type: project
---

「漂流者」是使用者的小說/角色專案,要為 6 個角色各訓練人物 LoRA。

- **素材原始位置(保留不刪)**:`G:\Codex\漂流者\角色\`(在 G:\Codex;使用者決定原目錄圖檔一律保留,只複製不搬移)。
- **claudecode 專案區(新)**:`G:\claudecode\drifter-lora_2026-06-30\`。周以諾放 `zhou_yinuo\`,下分 `01_source_datasets`(body_v2=90、face_v2=29,已從 v2 資料集複製、位元組核對一致)、`02_kohya_train`、`03_output`、`04_test`;`docs\` 有交接概要複本。之後其餘 5 角加同級子資料夾。
- **完整交接概要**:`G:\Codex\漂流者\LORA訓練_交接概要.md`(自包含,含各角現況、決策、環境參考)。
- **現況(2026-07-02)**:周以諾(觸發詞 `zhou_yinuo`)資料集基本就緒——`lora_dataset_v2` 90 張+caption、`lora_face_dataset_v2` 29 張+caption(皆 PNG、配對齊、無 jfif 問題),已複製進 claudecode 專案區。其餘 5 角(林曉14、蘇若冰9、王淺3、秦曼0、顧清歡0)還在前期,需擴增建集。
- **已拍板決策(2026-07-02)**:先練**周以諾**、用 **Flux**、在 **.161 那台 RTX 4060 Ti 16GB**(`D:\kohya_ss` flux_train_network,見 [[armor-lora-project]] 環境),v1 解析度 **768**。
- **訓練運行狀態(2026-07-02,已暫停待續)**:
  - .161 上路徑:`D:\lora_train\drifter\zhou_yinuo\`(body 90 + face 29,dataset.toml 用 num_repeats body×3/face×5 不複製檔;config=`train_zhou_yinuo_flux768_v1.bat`,輸出到 `output\`,log `logs\train_console.log`)。
  - Flux 四件套(ComfyUI portable 內):unet `...\diffusion_models\flux\flux1-dev.safetensors`(23.8GB)、`clip_l.safetensors`、`...\clip\flux1\t5xxl_fp16.safetensors`(9.8GB)、vae `...\vae\ae.safetensors`。
  - 訓練參數:networks.lora_flux dim16/alpha16、adamw8bit、lr1e-4、fp8_base、gradient_checkpointing、bf16、timestep_sampling shift、discrete_flow_shift 3.1582、max_train_epochs 6、save_every_n_epochs 1。啟動法=排程工作 `zhou_flux_v1`(schtasks /run,detached)。
  - **開跑前先清 GPU**:.161 平時有 ComfyUI + `D:\llama\llama-server.exe` 佔滿 VRAM,訓練前需先關掉。
  - **✅ 訓練完成(2026-07-02 22:13 → 07-03 03:31,約 5h18m)**:2490 步 6 epochs 乾淨跑完,7.6 s/it,avr_loss 0.27→0.248。產出 6 顆各 151MB(158,614,000 bytes):`zhou_yinuo_flux768_v1-000001..000005.safetensors` + 最終 `zhou_yinuo_flux768_v1.safetensors`(=epoch6)。log 的 79 個「Error」全無害(tensorflow 噪音、triton 未裝 fallback、git big5 解碼、mean ar err)。
  - **checkpoint 存放**:①原始在 .161 `D:\lora_train\drifter\zhou_yinuo\output\`;②本機備份 `G:\claudecode\drifter-lora_2026-06-30\zhou_yinuo\03_output\`(6 顆已核對);③已複製進 .161 `D:\ComfyUI_windows_portable\ComfyUI\models\loras\` 供測試。
  - **測試**:workflow + 說明在 `04_test\`(`zhou_yinuo_flux_lora_test.json` 原生 Flux dev 節點、`README_test.md`、`start_comfyui_listen.bat`),產圖在 `04_test\samples\`。用 ComfyUI API(POST /prompt→輪詢 /history→抓 /view)以指令直接生圖;模型檔名要從 `/object_info` 抓精確字串(含子資料夾反斜線 `flux\flux1-dev.safetensors`、`flux1\t5xxl_fp16.safetensors`,別手打)。
  - **epoch 4 泛化 OK 但「像」不足(2026-07-03 實測)**:`-000004` 臉/半身/全身/晚禮服/喜怒哀樂/動態多情境臉一致、換裝換景自如、無過擬合,但使用者反饋「有幾張不像」目標臉。四格對照(ep4/ep6 × strength1.0/1.2、同 seed 特寫)結論:**epoch 6 反而更不像(1.2 不像、1.0 跑掉),調參數已到頂救不回**。
  - **⚠️ 根因**:不像的根源在 caption + 資料集,非調參:①caption 把固定長相寫死→觸發詞綁不緊,多練只往「平均臉」收斂;②90 張「主資料集」其實=約 60 全身圖(臉小、保真低)+ 30 臉特寫混在一起。臉特寫聯絡表(`v2_face_closeups_selected_contact_sheet.jpg`)與基準臉吻合,身分確實在資料裡。
  - **基準臉**:`reference\zhou_yinuo_REF.png`(=源檔 2ba4d18c…jfif,768×1024,波浪髮+空氣瀏海+鎖匙墜項鍊+白羅紋上衣)。
  - **🔄 v2 訓練中(2026-07-03 ~14:xx 起)**:三改動=①精簡 caption(程式砍掉 young Taiwanese woman/black wavy hair/same identity/consistent face/skin texture 等固定長相,只留視角/表情/服裝/背景;原檔不動,v2 集在 `05_curation_v2\dataset_v2\`)②臉加重 body×2+face×6=354步/epoch③`--network_train_unet_only`(不練 CLIP-L)。2124 步 6 epochs、~7–8 s/it、約 4.5–5h。.161 路徑 `D:\lora_train\drifter\zhou_yinuo_v2\`,SYSTEM 排程 `zhou_flux_v2`,輸出 `zhou_yinuo_flux768_v2-00000N`。**策略:重點挑 epoch 3–4**(v1 epoch6 會 collapse)。
  - **✅ v2 完成並驗收(2026-07-03)**:6 顆存 `05_curation_v2\output_v2\`(本機備份)+ .161 loras。比對基準臉,**v2 明顯比 v1 像**(空氣瀏海抓到了、臉型更近),使用者驗收「可以」。**成品=v2 epoch 4**,已複製為 `zhou_yinuo_FINAL_v2ep4.safetensors`,測試 workflow 預設也改成 v2-000004。比對圖 `05_curation_v2\compare_ref_v1_v2.png`。ep3 幾乎等同可互換。周以諾 LoRA 至此完成;其餘 5 角(林曉/蘇若冰/王淺/秦曼/顧清歡)仍待建集。
  - **給檔案給使用者**:G: 是網路磁碟 `\\192.168.3.28\g`,markdown 絕對路徑連結點不開;改用 `explorer.exe "路徑"` 直接開檔案總管最可靠。
  - **.161 測試環境注意**:ComfyUI 用 `start_comfyui_listen.bat`(--listen 0.0.0.0 --port 8188、本機輸出、無 pause)經 SYSTEM 排程 `comfyui_zhou` 啟動,瀏覽器 http://192.168.1.161:8188。測試期間 llama-server 未開(留 VRAM)。曾一度整台掉線(ping 不通)後自行恢復、ComfyUI 重新監聽。
  - **⚠️ 啟動關鍵教訓**:`schtasks /run` 在**非互動(SSH)**情境下,若工作用預設使用者建立會**不執行**(Last Result 267011 = SCHED_S_TASK_HAS_NOT_RUN,回「成功」是假象、無 log 無快取)。**解法=建工作時加 `/ru SYSTEM /rl HIGHEST`**(Session 0 可跑 CUDA、`/run` 立即觸發、免登入會話、SSH 斷不影響)。此為 .161 上跑 detached 訓練的正解,勝過 [[armor-lora-project]] 舊記法。
  - 小注:預設連 CLIP-L 也一起練 LoRA(72 模組);若 v2 要只練 U-Net 加 `--network_train_unet_only`。git `dubious ownership` 警告無害(SYSTEM 讀不到 sd-scripts/.git),要消除可 `git config --global --add safe.directory D:/kohya_ss/sd-scripts`。之前 SSH 被 RST 是砍 ComfyUI/llama 後短暫重載造成,非訓練所致。
- **雷區**:原圖 .jfif 需轉檔;部分圖有 ✦ 生成器浮水印要清。
- 資料集流程用全域 skill `comfyui-lora-dataset-prep`;訓練環境經驗見 [[armor-lora-project]]。
