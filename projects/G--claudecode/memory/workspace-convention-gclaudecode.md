---
name: workspace-convention-gclaudecode
description: "工作區統一放 G:\\claudecode,每專案一資料夾,命名 topic_YYYY-MM-DD (ASCII kebab)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c2943ddb-8464-418a-99a4-e619a638cba6
---

使用者的工作區集中在 `G:\claudecode\`(與 ComfyUI `G:\ComfyUI_windows_portable\` 同槽)。規則:

- **單位**:每個主題/專案一個資料夾。
- **命名**:`topic_YYYY-MM-DD`(專案名在前、日期在後),英文 ASCII、kebab-case(日期=專案起始日)。照主題字母排序,方便按主題找。
- **內部**:資料夾內可再分子目錄,依專案彈性(如 `input / dataset / workflows / output`;3D 專案用 `src / 360 / 3d`)。
- **例外**:既有的 `G:\claudecode\art`、`G:\claudecode\政治漫畫` 原地保留、不改名、不套規則。

**Why:** 集中管理、與 ComfyUI 同槽存取方便,且 ASCII+無空格路徑避免 ComfyUI/Python 讀中文或空格路徑出錯。

**How to apply:** 新工作要建資料夾時,一律建在 `G:\claudecode\topic_YYYY-MM-DD\`。注意 Claude Code 工作區是啟動時決定的,無法對話中途改;要讓 session 預設開在 G,需使用者啟動時選該路徑。已搬入的專案:`b01001-3d_2026-06-27`、`claude-code-teaching_2026-06-26`、`face-lora_2026-07-02`、`armor-lora_2026-06-26`(見 [[armor-lora-project]])。註:舊工作區 `C:\Users\capbair\Documents\claude code desktop\` 仍有甲冑樣本圖 `_sample_*.png` 尚待歸入 armor-lora。
