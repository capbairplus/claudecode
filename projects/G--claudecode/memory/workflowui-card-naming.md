---
name: workflowui-card-naming
description: WorkflowUI 卡片標題的命名原則:先英文(模型/技術名)再中文說明,例如「Krea 2 Turbo - 角色設定圖 · 自動批次」
metadata:
  type: feedback
---

WorkflowUI 卡片的 `title` 一律 **先英文、再中文**,中間用 `-` 分隔:

```
Krea 2 Turbo - 角色設定圖 · 自動批次
```

而不是 `角色設定圖 · 自動批次(Krea 2 Turbo)`。

**Why:** 卡片以模型/技術為主軸分類,英文放前面在首頁列表裡一眼就能掃到是哪個模型,
中文說明退居後面當補充。既有卡片如 `Txt2Img Flux (Flux 角色文生圖)`、
`Political Cartoon Flux (政治漫畫生成)` 都是這個形態,新卡要跟上。

**How to apply:** 新增或修改 `workflow_templates/<id>/manifest.json` 的 `title` 時,
先寫英文的模型或技術名稱,再接中文用途描述。相關的還有
[[workflowui-vision]] 與 [[card-optional-stage-pattern]]。
