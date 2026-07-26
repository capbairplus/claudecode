---
name: project-b26-multicolor-lora
description: SOLIS B26 系列(3 花色共用一顆 LoRA)訓練現況，含「完全不留人物身分」的資料集處理原則
metadata: 
  node_type: memory
  type: project
  originSessionId: 3acdcb18-ad8f-4d42-a2bb-4689ca9a5cc7
  modified: 2026-07-26T04:24:56.092Z
---

第二個 backpack LoRA 專案，款式是 **B26**(束口斜背包)，跟 B19010(雙肩包)版型不同。核心差異：**這次是「一顆 LoRA 涵蓋多花色」**——B26005(橘)、B26006(藍格紋)、B26007(深灰格紋)共用一個觸發詞 `solisb26bag`，花色寫進 caption 當變數(`orange`/`blue plaid pattern`/`dark grey plaid pattern`)。只有 B26005 花色有 model 背著的實拍照，B26006/007 只有純商品照——刻意如此設計，因為「怎麼背」是版型的事跟花色無關，商品照負責教顏色/花紋。

**素材來源**：`G:\claudecode\SolisProduct\Source\B26005\`
- `Backpack\B26005\` `Backpack\B26006\` `Backpack\B26007\` — 純商品照(各花色)
- `B26005 models\` — 棚拍 look book(2 位不同真人 model：一女一男，斜背/手提穿法)
- `B26005 models\外拍\` — model 戶外實穿照(1 位真人，全程同一件毛絨外套)
- 排除 `外拍\濾鏡\` 子資料夾(跟外拍數量相同，是濾鏡重複版)

**關鍵政策轉變(這次 pilot 學到的教訓，比 B19010 v2 更嚴格)**：
1. **人物身分要 100% 歸零**——不只裁臉，[[project-backpack-lora-pilot]] 的 v2 做法(留 2 張露臉圖)使用者明確表示不要，這次**全部裁臉、不留例外**。
2. **身體/服裝也不能被學走**——不是靠裁切(裁到只剩包會犧牲太多姿勢資訊)，而是靠**混合多組不同真人拍攝的素材**(外拍毛絨外套 1 人 + 棚拍女生 2 套穿搭 + 棚拍男生 1 套穿搭 = 至少 4 種不同服裝/體型)+ **caption 如實描述每張的服裝**，讓服裝變成跨資料集會變動的「變數」而非恆定值——原理跟修好臉的問題一樣：只有「這張圖裡的東西每次都一樣」才會被觸發詞吸收，混合多場拍攝製造出的天然差異性就能避免服裝/體型被鎖死。
3. **不用 FaceDetailer**局部重繪臉部——會讓臉不自然，使用者明確反對。
4. **不用 IPAdapter 局部重繪 logo**——`x-flux-comfyui` 外掛跟 ComfyUI 核心不相容(見 [[reference-161-training-machine]])，而且使用者說效果不好，儘量避免。
5. **裁臉用臉部偵測(不是猜比例)**：ComfyUI 的 `UltralyticsDetectorProvider`(`bbox/face_yolov8m.pt`) + `ImpactSimpleDetectorSEGS` + `SegsToCombinedMask` 抓臉部 mask 的 bounding box，裁到臉部下緣+margin，比憑肉眼猜「裁掉上面 20%」準確得多——B19010 v2 就是這樣做才成功的。有些照片(背面/側面看不到臉)偵測不到臉是正常的，不需要裁切。

**Logo**：已準備乾淨版參考圖 `G:\claudecode\SolisProduct\logo\soluna_logo_no_border.png`(SOLUNA 是 SOLIS 底下的子品牌，B26 系列用這個 logo，不是 B19 系列的「SOLIS Düsseldorf」)。B19010 案例發現裁臉後 logo 意外變清楚，這次裁得更乾淨，理論上 logo 應該更穩，先不做 IPAdapter。

**資料集規模**：
- `product_clean/` 12 張(橘/藍/深灰各 4 張，含正面/背面/背帶特寫/側面或平拍)，repeats 20
- `worn_context/` 35 張(全橘色，混合戶外+棚拍女兩組+棚拍男一組，含「雙肩背/單肩斜背/手提」三種穿戴狀態，如實標註)，repeats 3
- 每 epoch 345 張、6 epoch 共 2070 steps，比 B19010(1020 steps)久，預估 4.5~5 小時

**輸出位置**：`G:\claudecode\output\solisb26bag\`(測試生圖統一存這裡，取代原本的系統暫存路徑)

**How to apply**：下次接手先查 `.161` 上 `D:\kohya_ss\dataset\solisb26bag\log\train_console.log` 跟 `model\` 訓練完成狀況。測試時：不用 FaceDetailer、不用 IPAdapter；生圖 prompt 用花色詞(`orange`/`blue plaid pattern`/`dark grey plaid pattern`)切換三款包；驗證重點除了顏色/logo，還要確認**不同 seed 生出的臉、體型、服裝風格是否夠多樣**(不能鎖死成某一個真人樣子)。
