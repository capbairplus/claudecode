---
name: qingming-parallax-prototype
description: 清明上河圖「鍵鼠自由視角」2.5D 位移原型(虹橋段)的位置、做法、實測結果與授權限制
metadata:
  type: project
---

使用者想要《清明上河圖》能用鍵盤滑鼠多角度移動觀看(**不是頭盔 VR**)。2026-10-27 做了第一輪可行性實測,專案在 `G:\claudecode\qingming-parallax_2026-10-27\`(README.md 有結構與重跑指令)。

做法:Wikimedia Commons 公有領域原圖(38414×1800)→ 裁虹橋段 4800×1800 → Depth Anything V2(transformers,ComfyUI 內建 python 跑)→ three.js 位移網格檢視器。鍵盤、滑鼠拖曳都已實測可用。

實測結果:35° 內自然、50° 開始拉伸、65° 散掉;前景高聳物(鷹架/桅杆)轉角度後拉成條紋;來源圖高度只有 1800 px。

**Why:** 如果之後要擴成整卷或商用,這幾點是已知的天花板。Depth Anything V2 的 Base/Large 是 CC-BY-NC-4.0(僅限非商用),只有 Small 是 Apache-2.0,商用要換 Small 或別的模型。

**How to apply:** 使用者再問這個題目時,先看專案 README 與 `shots\` 截圖,不要從零重做。下一步候選:整卷分塊深度並統一尺度、前中後景分層+補洞(inpaint)、重點物件(虹橋、船)圖轉 3D。相關背景見 [[workspace-convention-gclaudecode]]。
