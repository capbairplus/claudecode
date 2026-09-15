---
name: bellabarnett-reference-library
description: Bella Barnett 全站商品圖參考庫的位置、規模與用途(fashion_model_bb_flux 卡與 try-on 的素材來源)
metadata:
  type: project
---

2026-09-14 抓下 bellabarnett.com 全站圖庫,兩份完整副本:

- `G:\claudecode\bellabarnett-ref_2026-09-14\` (NAS)
- `capbair@192.168.1.7:D:\BellaBarnett` (007,原始下載處)

內容:`images\` 1,666 張主圖(原尺寸 1500×2250,給 try-on 當 garment 來源)、
`details\` 8,949 張細節圖(768px,依服裝類型分 11 桶)、`hero\` 3,610 張分類形象照
(1024px,外景 editorial 調性,跟商品頁的灰棚完全不同)。共 14,225 檔。

用途:① 重寫 `fashion_model_bb_flux` 卡的服裝語彙 ② 餵 `tryon_qwen` 做精準換裝。

**Why:** 純靠商品名稱寫 prompt 會失真 —— 第一版照商品命名寫,Flux 生出一堆素面針織
洋裝,跟網站完全不像。看過實拍才發現關鍵不是材質名而是「裝飾長在哪裡」。

**How to apply:** 要改卡片語彙或找特定版型時,直接看 `details\` 裡的圖(檔名是商品
handle,同商品的 `__01`/`__02`… 相鄰)。`__01` 是正面全身,`__02`/`__03` 多為背面與
細節特寫,後者才看得出鑲飾走線。相關:[[fashion-model-bb-flux-card]]
