---
name: feedback-benchmark-against-previous-best
description: 做 AI 影片新版本前,先拿同專案前一版最佳成品當品質基準對比;我做的阿鍚玉 MMA v2 被評「比 Codex 版差好幾個檔次」
metadata:
  type: feedback
---

接手或重做 AI 影片時,**動工前先把同專案前一版最好的成品抽格看過、當品質基準**,每完成一段就並排比對;品質明顯掉了就停下來修流程,不要只照「動作有沒有演出來」逐鏡放行。

**Why:** 2026-11-21 阿鍚玉 MMA v2(Claude 做)被使用者評為比 Codex 版 MMA 差好幾個檔次:人物不一致、動作爛。根因是我自己的流程:首尾幀混用三種來源(Codex 參考圖、Qwen 2511 第二代改圖、Wan 抽出的真實影格)導致臉與服裝逐鏡在變;改用 Wan 2.2 Q4+Lightning 49 幀/16 fps×20 鏡(Codex 版是 HyperFlow H3 124 幀/24 fps、14 段);QA 只看 416×240 接觸表、沒做臉部一致性檢查、有 inswapper face_fix 也沒用;開工前沒看過 Codex 版。

**How to apply:** 開工前抽格看前一版最佳成品並說明要沿用它的哪些做法;首尾幀來源要統一並以定錨圖為準(不要從改過的圖再改);每個關鍵幀與成片過 InsightFace 臉部相似度門檻;動作與人物一致性兩項都要並排比對前版才放行。相關:[[feedback_verify_before_answering]]、[[su-ruobing-dataset-progress]]
