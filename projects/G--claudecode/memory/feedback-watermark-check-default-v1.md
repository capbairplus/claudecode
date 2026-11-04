---
name: feedback-watermark-check-default-v1
description: 檢查浮水印時預設照 v1(docs\浮水印殘存嚴格檢查_HANDOFF.md,最初建立 task 的規範,含後續修正);使用者明講「用 v2」才改用 rule\ 的檢查規範 v2
metadata:
  type: feedback
---

被要求「檢查浮水印」(殘存浮水印嚴格檢查)時,**預設照 v1 做**;使用者明確說「用 v2」才用 v2。

- **v1(預設)** = `D:\MyProject\MyTraining\docs\浮水印殘存嚴格檢查_HANDOFF.md`——最開始建立檢查 task 所用的規範,後來有被修正(例如第 4 節 C3 改自適應粗到細、R1 也算 FAIL、第 12 節演算法課新增項目)。每次開工都重讀它的**現行內容**,不憑記憶。
- **v2(只在被交代時用)** = `D:\MyProject\MyTraining\watermark\rule\殘存浮水印嚴格檢查規範_v2_20261104.md`(條文 V1–V11)。其延伸 `rule\殘存浮水印檢查_雙演算法交叉驗證規範_v1_20261104.md`(X1–X12)檔名雖帶「v1」,**不是**這裡說的預設 v1,同樣屬 v2 體系,只在被交代時用。

**Why:** 2026-11-04 使用者原話:「以後要你去檢查浮水印時你就用 v1 版,交待妳用 v2 妳才去用 v2」;我問「v1 指哪一份」,他答:最開始建立 task 所使用的規範(後來有修正)。

**How to apply:** 開工前先讀 HANDOFF 現行版,照它的第 0–12 節與第 9 節交付格式(報告路徑、`residual_ranges.csv`、遮蔽規則)做;不要主動套用 v2 的 V1–V11/X1–X12 或它的報告格式。HANDOFF 內的保密/禁止事項(不寫字串與電話、不重編碼、不碰 OBS 等)仍然有效。不確定使用者指哪一版時先問,不要猜。去除端的規範是另一件事,見 [[watermark-spec-location]]。
