---
name: feedback-no-unilateral-action
description: 使用者明確要求進入純討論模式時，不准擅自動作(改檔案/查資料/跑工具)，先討論定案再動手
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7239123b-9598-4a13-9318-42321c781c67
  modified: 2026-08-12T14:57:20.089Z
---

使用者說「先討論，從現在開始我們只討論，你不要擅自動作」時，代表接下來的回合只能用文字討論，不可以呼叫任何會改變狀態或執行動作的工具（包含 Edit/Write 改檔案、跑指令、甚至 WebSearch/WebFetch 查資料），直到使用者明確說可以動手為止。

**Why:** 在《Codex 入門》書籍改版討論中，使用者對書的定位(Codex 整體 vs 只講 Codex CLI、skills/plugin/MCP 該不該當核心)提出質疑，過程中我多次在對話中主動發起 WebSearch/WebFetch 查證，被使用者連續中斷兩次工具呼叫並動怒（"你是在裝傻嗎"、"他媽的"）。之後使用者直接下令「只討論，不要擅自動作」，要求先把方向談清楚、達成共識，再進入實際查證或修改階段。這與 [[feedback-brainstorm-style]] 的精神一致——brainstorm/討論階段要用文字對話收斂，而非自己搶跑動作。

**How to apply:** 收到「先討論」「你不要擅自動作」這類指示後，接下來的每個回合都只用文字回應，即使看起來有「顯而易見該做的下一步」(例如查證某個功能是否存在)，也要先用文字提出、等使用者明確說「查」「動手」「go ahead」之類的話再呼叫工具。這條規則會持續到使用者明確解除為止，不是只管當下這一句。
