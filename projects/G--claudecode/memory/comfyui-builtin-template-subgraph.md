---
name: comfyui-builtin-template-subgraph
description: "ComfyUI 內建官方 template 現在把 graph 包成 subgraph,要從 definitions.subgraphs 展開才拿得到 proven 節點結構;含取得 template 的 HTTP 端點"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 6ea7b37a-af12-47e6-b0a7-b662e75955fe
  modified: 2026-08-16T07:41:27.319Z
---

做新卡時,**ComfyUI 內建的官方 template 是最好的 proven graph 來源**,不用自己拼也不用開瀏覽器匯出。

**怎麼拿**(對 .161 直接打 HTTP,不需要 SSH):
- `GET /templates/index.json` — 列出全部內建 template(每筆有 `name` / `title`)。
  注意 `GET /api/workflow_templates` 是**另一回事**,那只回 custom node 自帶的 template。
- `GET /templates/<name>.json` — 拿單一 template 的 workflow JSON。
- 回來的檔案有 **UTF-8 BOM**,python 要用 `encoding='utf-8-sig'` 才讀得動。

**關鍵陷阱:新版 template 幾乎都把主要 graph 包成 subgraph。**
頂層 `nodes` 看起來只有 LoadImage / SaveImage 加一個 `type` 是 **UUID** 的節點(例如
`7b34ab90-36f9-45ba-a665-71d418f0df18`),真正的節點結構在 **`definitions.subgraphs[]`** 裡,
每個有自己的 `nodes` / `links` / `inputs`。要寫 `workflow_api.json` 就得手動展開:
- subgraph 內的 `links` 是 dict 形式(`{'id','origin_id','origin_slot','target_id','target_slot','type'}`),
  跟頂層 `links` 的 list 形式不同。
- `origin_id: -10` 代表「來自 subgraph 的外部輸入」,`target_id: -20` 代表「接到 subgraph 的輸出」。
- 對照 `widgets_values`(位置陣列)要用 `/object_info/<NodeClass>` 的 **`input_order.required`** 逐一對位,
  別憑印象猜參數順序。例如 `ImageScaleToTotalPixels` 其實有 4 個參數
  (image, upscale_method, megapixels, **resolution_steps**)。
- template 裡寫死的模型檔名**不一定存在於 .161**,送出前一定要用 `/object_info` 的 combo 清單核對。

相關:[[comfy-161-network-access]] [[workflowui-instruct-edit-cards]]
