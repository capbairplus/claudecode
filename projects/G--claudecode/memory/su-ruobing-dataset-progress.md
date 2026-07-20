---
name: su-ruobing-dataset-progress
description: 蘇若冰 Flux LoRA 資料集進度與「表情/角度變體用 Qwen Edit、別用 ChatGPT 瀏覽器」的教訓
metadata:
  type: project
---

蘇若冰(《漂流者》角色)Flux LoRA 資料集，臉部素材現況(2026-07-05)：
- `03_face_variants/`：15 張多角度多表情大頭照(Qwen multi-angle),已臉把關全過。
- `07_expr_qwen/`：14 張情緒表情(fear/panic/gasping/despair/crying/pain/exhausted/determined/wary/relief/anger/sorrow/joy/confusion),船難+荒島用。Qwen Image Edit 2511 生,InsightFace 全過(0.53–0.90;激烈張嘴表情分數自然較低仍 >0.45)。含 `_contact_su_expr.png`、`gating_report.txt`。
- `08_hair_qwen/`：7 張髮型狀態(濕髮貼額/後梳/風吹/落難凌亂/暴雨/汗濕/雨後 × 戶外/陰天/烈日/暴風 × 白襯衫/破舊灰衣/海軍藍),用來打散「棚拍乾髮+灰底+海軍藍」綁定。全過(0.65–0.83)。
- **臉部素材合計 36 張**(15 角度 + 14 表情 + 7 髮型),身分皆把關過,角度/表情/髮型/打光/衣服都有變化。腳本:su_face_gen.py / su_expr_qwen.py / su_hair_qwen.py。
- `09_body_qwen/`：26 張全身/半身(Qwen Edit,參考=全身圖 su_src_07),鏡位/角度/服裝/場景/姿勢(含坐/蹲/背面/叢林濕衣)全覆蓋。整批身分一致(0.43–0.65,全身臉小分數本就較低,無飄臉)。腳本 su_body_qwen.py。**取代先前外部生的 `Full/` 批(那批飄臉嚴重,19 張 <0.45,已作廢)。**
- **教訓補充**:全身圖也用 Qwen Edit、以「全身原圖」當參考最穩;別用無鎖臉的外部生成(會飄成別人)。Qwen 連坐/蹲/背面都能生對,pose 沒想像中弱。
- **資料集現況**:臉 36 + 身 22 = 58 張進訓練,全 Qwen、全把關過。
- **✅ LoRA 已訓練完成**:成品 `su_ruobing_flux768_FINAL_v1ep4.safetensors`(v1 ep4,觸發詞 `su_ruobing`,Flux dev,建議強度 1.0)。逐 epoch 測試 InsightFace:ep4 0.566 最高(ep6 冒項鍊雜訊、過度收斂)。備份在 `su_ruobing/10_train_output/`,.161 loras 已放成品。README:`su_ruobing/README_su_ruobing_lora.md`。訓練設定/腳本在 `_scripts/`。
- **踩雷**:dataset.toml 路徑要用**正斜線**(反斜線經 heredoc 折成單反斜線 → TOML `Reserved escape sequence` 崩)。已補進 skill。
- **v1 像度不足教訓**:v1 臉集混入 14 激烈表情 + 7 濕亂髮(臉飄 0.53–0.6)+ caption 太省 → 學成平均臉,比周差。對照發現**周 v2 身分訓練只用「多角度 neutral 臉29 + 整圈轉台全身90」,零激烈表情/髮型**,caption 標滿衣服背景。訓練設定我和周其實一樣(不是設定錯)。
- **v2 進行中**(照周配方):臉只留多角度 neutral、剔表情/髮型;補整圈轉台全身(`09b_body_turntable`);細 caption;同設定重練。
- **標準化 runbook 已寫入 skill `flux-character-lora-training`**(每角色只換觸發詞+2參考圖+路徑;身分訓練素材=多角度 neutral,表情/髮型/場景是「生圖用」不進訓練)。四角色(lin_xiao/wang_qian/qin_man/gu_qinghuan)前置已備(`source/_PREP_4chars.md`),照 runbook 一位一位跑。
- 基準臉:`su_ruobing/e40fa5de-...jpg`(= 01_source_png/su_base_expr.png,正臉海軍藍襯衫、無首飾)。
- 全身基礎照使用者另用別法生,尚未併入。

**教訓(重要)**:角色表情/角度變體，**用 .161 的 Qwen Image Edit(4-step,腳本 su_expr_qwen.py)最快最穩**——14 張幾分鐘、身分高度一致。曾嘗試用 claude-in-chrome 驅動 ChatGPT gpt-image 生成，雖能保臉，但踩雷連連:OS 剪貼簿與使用者搶用導致貼錯圖、ctrl 卡住把瀏覽器縮放到 250%、擷取視窗凍結成 258×188、擴充斷線——又慢又不穩。**下個角色直接走 Qwen。**
**Why:** 使用者對速度與穩定敏感,ChatGPT 瀏覽器自動化這條路被驗證為劣解。
**How to apply:** 沿用 [[drifter-lora-project]] 的 Qwen 變體流程;把 su_expr_qwen.py 的 REF/SHOTS 換掉即可套到別角色。crying 類避免用 "eyes red"(會生血淚),改 "clear glistening tears"。
