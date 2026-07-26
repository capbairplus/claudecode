---
name: project-backpack-lora-pilot
description: SOLIS 後背包 B19010核桃紫 pilot LoRA 訓練專案現況與資料位置
metadata: 
  node_type: memory
  type: project
  originSessionId: 3acdcb18-ad8f-4d42-a2bb-4689ca9a5cc7
  modified: 2026-07-25T18:27:39.967Z
---

SOLIS(後背包品牌)想用既有商品照 + model 展示照，讓 ComfyUI 生成的虛擬 model 背著公司的包出圖/影片。第一個 pilot 選的是 **B19010「核桃紫」**款(拼接休閒後背包 B19 系列)。

**Why**：B19 系列裡這個花色的素材最齊全(19 張 model 背著/提著實拍照 + 5 張棚拍商品照 + 4 張去背商品照)，適合當驗證整條流程的起點。之後若成功可套用到其他花色(B19011~B19015)或其他包款。

**資料位置**：
- 原始素材備份：`Z:\backup\all\sg\public\【SOLIS商品.人物.網拍圖】\`(公司共用照片庫，近 8 萬檔，勿整包掃)
- 專案工作目錄：`G:\claudecode\SolisProduct\`(使用者指定，不套用一般 `topic_YYYY-MM-DD` 命名慣例)
  - `dataset/raw/` — 複製自 Z 槽的原始 28 張(model/product/product_cutout)
  - `dataset/processed/img/product_clean/`(5 張，repeats 16) 與 `img/worn_context/`(18 張，repeats 5) — 已篩重複、已打標
  - `dataset/processed/dataset.toml` — 本機留存的設定備份(實際訓練用的版本在 .161 上)

**觸發詞**：`solisb19010bag`。Caption 策略：logo/拉鍊/口袋等固定特徵不寫進 caption(讓觸發詞吸收)，姿勢(背著雙肩帶/手提側背帶/放置)、視角、背景如實標註為變數——因為原始 model 照片裡只有 5 張是真正「背在背上」，其餘是手提，混著訓練必須標對，否則 LoRA 會學錯背包與身體的空間關係。

**v1 訓練與踩雷(2026-07-25 深夜)**：第一版訓練跑完(6 epoch，`solisb19010bag_flux768*.safetensors`)，測試後發現兩個問題：
1. **顏色沒還原**——LoRA 權重 1.0 生出來背包是黑色，不是核桃紫。**修法：權重拉到 1.3~1.6** 顏色就對了，不用重練——這是「LoRA 強度不夠蓋過底模『後背包=黑色』的強先驗」，不是沒學到。
2. **虛擬 model 長相被鎖死成同一個人**——18 張 worn_context 訓練圖裡有 78%(14/18)都露出同一位真人 model 的臉，caption 又沒描述她的長相，導致臉跟背包一起被觸發詞吸收。查證過網路上牛仔褲/夾克 LoRA 的實戰案例，結論是：**臉在訓練圖裡出現的比例才是關鍵，不是 caption 寫不寫**（如果每張 caption 文字都一樣，寫不寫臉部描述沒差，因為文字本身也是恆定的）。正確做法是**把臉整個從構圖裡裁掉**，只留肩膀以下。

**v2 訓練(2026-07-26 凌晨)**：用 ComfyUI 內建的臉部偵測(`UltralyticsDetectorProvider` + `ImpactSimpleDetectorSEGS` + `SegsToCombinedMask`，模型 `bbox/face_yolov8m.pt`)抓出每張 worn_context 圖的臉部座標，精準裁掉臉(只留 `IMG_5028.JPG`、`_DSC1830.jpg` 兩張露臉，其餘 16 張都裁到下巴以下)，資料夾改名 `worn_context_v2`，其餘設定不變，重新跑 6 epoch(輸出 `solisb19010bag_flux768_v2*.safetensors`，路徑 `model_v2/`、log 在 `log_v2/`）。舊的 v1 資料/模型保留未刪，本機備份在 `dataset/processed/img/worn_context_old_backup/`。

**logo 清晰度**：嘗試過用 IPAdapter(`x-flux-comfyui`)+ 真實 logo 圖局部重繪，卡在外掛與 ComfyUI 核心版本不相容(見 [[reference-161-training-machine]])，2026-07-26 尚未解決。使用者提供的乾淨 logo 檔在 `G:\claudecode\SolisProduct\logo\Solis Logo.jpg`(黑底白字 SOLIS Düsseldorf)。

**How to apply**：下次接手先確認 `.161` 上 `D:\kohya_ss\dataset\solisb19010bag\log_v2\train_console.log` 跟 `model_v2\` 的 v2 訓練結果有沒有跑完；测试時記得 LoRA 權重用 1.3~1.6，不要用預設 1.0。用法是把這顆背包 LoRA 跟任何角色 LoRA(或純文字描述的人物)一起疊加載入 ComfyUI，背包 LoRA 只管背包長相/背負關係，v2 版本應該不再綁定特定人物身分（待驗證）。
