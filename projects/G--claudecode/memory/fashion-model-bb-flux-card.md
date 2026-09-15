---
name: fashion-model-bb-flux-card
description: fashion_model_bb_flux 卡(Flux 時尚女模 - Bella Barnett 風)的設計要點與 try-on 搭配方式
metadata:
  type: project
---

C# 正式版新卡 `fashion_model_bb_flux`(標題「Flux 時尚女模 - Bella Barnett 風」),
2026-09-14 建立。wildcard 在 `C:\wordpresscb\workflowui-wildcards\fashion_bb\`。

三個關鍵設計:

1. **只出單張,不做合板。** template.yaml 開頭是 `A high-end fashion lookbook
   photograph of a single adult woman`。舊卡 charsheet 的 `A professional model
   reference sheet ... arranged side by side` 那句話本身就在要求多格。
2. **服裝語彙寫「裝飾長在哪裡」**,不是材質名。`pearl embellished gown` 只會得到
   素面洋裝;要寫 `pearls scattered in a spaced grid across the whole bodice and skirt`。
3. **畫質尾綴要包妝髮與配飾**(中分順直長髮、暖銅眼影、誇張耳環、堆疊手環、
   水鑽細帶高跟鞋)。少了這段,生出來的圖會切在腳踝而且配飾全空。

**Why:** 前兩版都失敗過 —— v0 生出合板(其實是誤按自動批次),v1 照商品名寫語彙
生出素面針織洋裝。第三版看過 8,949 張實拍才寫對。

**How to apply:** 全身務必搭直式 832×1216(Flux 版面服從度差,寬幅會被拉成合板)。
要「就是這一件」而不是「這種風格」,用 `tryon_qwen`:把這張卡的產出當 person_image,
[[bellabarnett-reference-library]] 的商品圖當 garment_image。**試穿指令要改寫** ——
預設那句寫著 `keep ... buttons, collar shape`,會讓模型憑空補出釦子和襯衫領;
改成明列該有什麼、並加 `do not add any collar, buttons, zips, seams or trim that
are not visible in the second reference image`,實測一次就修正。
