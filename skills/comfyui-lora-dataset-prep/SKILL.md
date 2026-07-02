---
name: comfyui-lora-dataset-prep
description: >-
  準備、擴增、清理與打標 LoRA 訓練資料集的完整流程(ComfyUI / kohya sd-scripts /
  SDXL / Flux 通用)。當使用者想「做 LoRA 資料集」「準備訓練資料」「資料集擴增」
  「打標 / caption / tag」「收集訓練圖」「素材只有幾張要怎麼練 LoRA」,或討論
  觸發詞、資料夾 repeats 結構、WD14/Florence 打標時,務必使用本 skill——即使
  他們沒明講「資料集」三個字。涵蓋人物、風格、概念/物件各類 LoRA。
---

# ComfyUI 通用 LoRA 資料集準備

幫使用者把「一堆(或很少)素材」變成一份**可直接訓練**的 LoRA 資料集:
足量且多樣的圖 + 正確的 caption + 正確的資料夾結構。訓練品質有 8 成取決於資料集,
所以這一步值得做對。

## 核心原則(先讀,決定一切)

1. **先定 LoRA 類型再動手**——人物/臉、風格、概念/物件,三者的資料量、多樣性、
   caption 策略完全不同(見 Step 1)。做錯類型的 caption 是最常見的失敗原因。
2. **多樣性 > 數量**。同一角度同一表情的 50 張,不如 20 張角度/光線/背景各異的。
3. **caption 是在「告訴模型哪些是變數、哪些是要學的常數」**。要學進觸發詞的特徵
   就「少打標」;會變動、不想綁死的(背景、服裝、姿勢)就「打出來」。這條原則
   貫穿整個打標,細節見 `references/captioning.md`。
4. **路徑用 ASCII、無空格**(見 [[workspace-convention-gclaudecode]] 全域慣例)。
   跑 Python 打標/裁切時,cp950 系統務必設 `PYTHONUTF8=1`,否則中文檔名或 log
   會觸發 UnicodeError 崩潰。

## 五步流程

### Step 1 — 定義需求(依類型)

先問清楚要練哪一類,再套下表當起點(非硬規則,可依素材調整):

| 類型 | 建議張數 | 多樣性重點 | caption 策略 |
|---|---|---|---|
| **人物 / 臉** | 15–40 | 角度、表情、光線、背景 | 觸發詞 + 少打臉部特徵;背景/服裝/姿勢打出來 |
| **風格** | 30–100+ | 題材、構圖、主體多樣(才不會連內容一起學進去) | **短 caption + 專屬罕見觸發詞**;描述「畫了什麼」不描述「風格」 |
| **概念 / 物件** | 20–60 | 角度、背景、情境 | 觸發詞 + 物件關鍵描述 |

多概念(例如一個 LoRA 想分 15 個朝代)= **每個概念一個專屬罕見觸發詞 + 各自資料夾 + 極簡 caption**。
用通用詞(如 `qin dynasty`)會撞底模先驗、長句 caption 會稀釋訊號,導致各概念被平均成一團。
(這是實戰教訓,細節見 `references/captioning.md`。)

### Step 2 — 取得素材

- **素材足量** → 直接進 Step 3。
- **素材不足 / 只有單張**(常見於「用一張大頭照做 LoRA」)→ 先**擴增**出多角度、
  多表情、多情境的圖。方法很多(LivePortrait、Qwen 多角度 LoRA、Flux Kontext、
  InstantID+ControlNet、ReActor、Zero123…),依「要表情還是要角度、本地還是雲端」
  選路線。**完整方法與選型見 `references/augmentation.md`。**
- 擴增後一定要**人工篩選**,別把生成瑕疵直接餵進訓練。

### Step 3 — 篩選與前處理

1. **去重 / 去劣**:刪掉重複構圖、模糊、瑕疵、主體佔比太小的。
2. **裁切隔離主體**:一圖一主體;多主體頁面要拆成單張。背景太雜可白底化。
3. **解析度 / bucket**:SDXL 常用 1024(VRAM 不足退 768);Flux 常用 768–1024。
   保留原始長寬讓 aspect-ratio bucketing 處理,不必硬裁成正方形。

### Step 4 — 打標 caption

- **anime/插畫類** → WD14 tagger(如 `SmilingWolf/wd-vit-tagger-v3`)。注意它對
  非動漫主體會給雜訊標(japanese_clothes/blue_hair 等),v1 可先容忍,之後再黑名單。
- **寫實/自然語言** → Florence-2 或 BLIP;但**風格/多概念 LoRA 慎用長自然語言**,
  會稀釋觸發詞(見核心原則 3 與 captioning.md)。
- **每張 caption 前面加觸發詞**。格式範例:`<觸發詞>, <類別/概念>, <其餘 tags>`。
- caption 存成與圖**同檔名的 `.txt`**,一圖一檔,放同資料夾。
- **完整打標策略(各類型範例、觸發詞設計、殘留文字處理)見 `references/captioning.md`。**

### Step 5 — 資料夾結構(kohya sd-scripts 慣例)

kohya 用「repeats_觸發詞」的資料夾名決定每張重複次數:

```
<專案>/
├── img/
│   └── 10_mytrigger/          ← 數字=repeats;裡面放 圖 + 同名 .txt
│       ├── 001.png
│       ├── 001.txt
│       └── ...
├── model/                     ← 輸出 LoRA
└── (log/、reg/ 視需要)
```

多概念平衡:張數少的概念調高 repeats、張數多的調低,讓各概念「repeats × 張數」相近。
ComfyUI 內建訓練節點的資料集格式略有不同,若走 ComfyUI 訓練需另行確認節點要求。

## 常見雷區(直接提醒使用者)

- 只有單張/少量就硬訓 → 過擬合。先擴增(Step 2)。
- 風格 LoRA 用長自然語言 caption → 風格學不純、概念糊。改短 caption + 觸發詞。
- 多概念用通用詞當觸發詞 → 撞底模先驗、彼此混淆。用專屬罕見觸發詞。
- 中文/空格路徑 + 沒設 PYTHONUTF8 → Python 崩潰。用 ASCII 路徑、設 UTF8。
- 生成擴增圖不篩選就訓練 → 把瑕疵學進去。

## 何時該深入 reference

- 使用者素材不足、要「擴增」 → 讀 `references/augmentation.md`。
- 要決定 caption / 觸發詞策略,尤其風格或多概念 → 讀 `references/captioning.md`。
