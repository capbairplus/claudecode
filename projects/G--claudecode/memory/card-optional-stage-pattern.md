---
name: card-optional-stage-pattern
description: 在一張 ComfyUI Card 裡做「可開關的可選階段」的兩個手法(ImpactConditionalBranch lazy / RIFE multiplier=1),已實證
metadata:
  type: project
---

WorkflowUI 的 manifest 規定**每個欄位都必須對到某個 `node_id` + `input_key`**,所以「要不要跑某一段」
沒辦法直接用一個開關表達。2026-08-20 做 `wan_vace` v2(Florence-2 自動 prompt + RIFE 補幀)時
實證出兩個可重複使用的手法:

**手法 1:`ImpactConditionalBranch` 當開關(可選的「整段子流程」)**
- `/object_info` 顯示它的 `tt_value` / `ff_value` 都是 `{"lazy": true}` —— 所以 `cond=false` 時
  **被關掉那一側的上游整條線根本不會執行**,不是跑完才丟掉,真的省時間。
- 接法:`Florence2Run.caption → tt_value`、`PrimitiveString("") → ff_value`,輸出再進
  `StringConcatenate`。manifest 開一個 `boolean` 欄位對到 `cond`。
- 輸出型別是 `*`(Impact 的 AnyType),接到 STRING 輸入不會被 ComfyUI 的型別檢查擋下來。
- ⚠ 關掉時 `StringConcatenate` 會留一個多餘的 delimiter(例如結尾 `", "`)。把使用者的手打文字放
  `string_a`、可選段放 `string_b`,這樣多出來的是**尾端**逗號而不是開頭,比較不礙眼。

**手法 2:`RIFE VFI` 的 `multiplier=1` = 原樣輸出(已實證)**
- schema 的 `multiplier` min 就是 1,實測 `multiplier=1` **不會報錯,輸出幀數與輸入相同**
  (33 幀進 → 33 幀出 / 16 FPS)。所以「不補幀」不需要額外的 bypass 節點。
- FPS 要一起連動,否則幀數變多但 FPS 沒跟上、片長會被拉長。用
  `MathExpression|pysssss` 的 `expression: "16*a"`、`a` 接倍數那個 `INTConstant`,
  取它的 **FLOAT 輸出(index 1)** 餵 `VHS_VideoCombine.frame_rate`。
  實測 2 倍:49 幀/16FPS → 97 幀/32FPS,片長 3.06 → 3.03 秒(沒被拉長)。

**Florence-2 自動反推 prompt 的實務細節**
- 用 `Florence-2-large-PromptGen-v2.0` + task `prompt_gen_mixed_caption`(沿用 `caption_florence`
  已驗證的設定)。`/object_info` 的 task enum 有 15 項,`prompt_gen_*` 那幾項在列表**後段**,
  查的時候別把 list 截斷了才以為沒有(我就這樣誤判過一次)。
- ⚠ **反推出來的 caption 不會留在 `_meta` 裡**。`_meta` 存的是送出去的 graph,caption 是執行期才算出來的,
  而 `Florence2Run` 的 caption 輸出沒接輸出節點就不會進 ComfyUI history。想留存要另外接存字串的輸出節點。

**wan_vace v2 實測耗時(480×832, 6 步, .161)**
- 49 幀 / 自動描述關 / 不補幀:314 秒(v1 基準)
- 49 幀 / 自動描述開 / 2 倍補幀:479 秒(+165 秒 = Florence 載入反推 + RIFE 補 48 幀)
- 33 幀 / 自動描述關 / 不補幀:220 秒

相關:[[workflowui-csharp-only]] [[workflowui-postprocess-cards-0816]] [[comfyui-builtin-template-subgraph]]
