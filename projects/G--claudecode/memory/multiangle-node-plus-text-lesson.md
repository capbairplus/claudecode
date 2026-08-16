---
name: multiangle-node-plus-text-lesson
description: "改角度/姿勢/表情這類效果時,光靠控制節點的數值輸入不夠,proven 腳本裡通常還把對應的英文描述直接寫進 prompt——複製 workflow 時兩者都要照抄"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 92ab833c-c89b-4938-aca8-e0caaec12ab3
  modified: 2026-07-25T05:59:51.522Z
---

**教訓(2026-07-25)**:第一版 `multiangle_qwen` 卡片只把數字 `horizontal_angle` 餵給
`QwenMultiangleCameraNode`,base_prompt 欄位在所有角度之間保持不變。使用者實測回報「沒有按角度轉」,
三張圖(0°/15°/345°)看起來幾乎一樣——是真的失敗,不是誤報。

**Why**:對照原本跑通的 `su_face_gen.py`,它的 `build_prompt(angle, expr)` 其實是把角度的**英文文字描述**
(例如 `"right 15 degree slight three-quarter view, both eyes visible"`)直接寫進 `string_a`(最終
prompt),節點的數值輸入(`QwenMultiangleCameraNode.horizontal_angle`)只是輔助,不是唯一驅動力。我
複製 graph 結構時只搬了數值輸入那條路,漏了「顯式文字描述」這條路,導致控制訊號太弱、模型幾乎沒反應。

**How to apply**:
- 照抄一個「用 XXXNode 控制某個效果」的 proven workflow 時,除了看 graph 節點結構,**一定要回頭看
  原始腳本的 Python 邏輯**(不只是 workflow_api.json),確認是否有额外把描述文字手動塞進某個
  `CLIPTextEncode`/`StringConcatenate` 之類的輸入——很多 ComfyUI 自訂節點(角度/姿勢/表情/光線控制)
  設計上就是「數值節點 + 文字提示雙重驅動」,只搬其中一半會看起來「有跑但沒效果」,不會報錯,很容易
  被誤判成「模型能力就是這樣」而不是「我漏東西了」。
- WorkflowUI 的 `RepeatRowField` 因此加了 `mode: "append"`(見 `manifest_schema.py`/
  `workflow_engine.py`),讓 repeat 的每一列可以把文字**接在**已有的 base prompt 後面,而不是整個蓋掉
  ——之後做圖生影片/lip sync 這類同樣靠「控制節點+文字」雙重驅動的功能,大概率會再用到同一個模式。
- 修完一定要**真的跑幾張不同參數值的圖去肉眼比對**(不能只看 graph 沒報錯就當作對),這次就是靠實際
  對比 0°/15°/345° 三張圖才抓到問題、也才確認修好。

相關:[[workflowui-vision]]
