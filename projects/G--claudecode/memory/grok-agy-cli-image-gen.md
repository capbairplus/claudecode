---
name: grok-agy-cli-image-gen
description: 本機 grok CLI(image_gen/image_edit)與 agy(Antigravity,image-generator 子代理)都能照參考圖生圖、服裝一致性與 Codex 同級;各自的存圖位置、安全旗標與 grok 中文路徑超長的雷
metadata:
  type: reference
---

2026-11-22 實測(阿鍚玉 MMA 服裝總錨當參考,畫兩人互抓前臂),兩者服裝逐項對上總錨:

- **grok**:`C:\Users\capbair\.grok\bin\grok.exe` 1.0.89,grok.com 登入,預設 grok-4.7。內建 `image_gen`、`image_edit` 工具。headless:`grok -p "<prompt>" --cwd <dir> --tools "image_edit,image_gen,read_file" --allow image_edit --allow image_gen --allow read_file`。約 104 秒,1280×720 JPG,圖存在 `C:\Users\capbair\.grok\sessions\<cwd 百分比編碼>\<session>\images\1.jpg`,要自己 `Copy-Item -LiteralPath` 出來。
  - **雷**:session 資料夾名 = cwd 的百分比編碼,中文字一個變 9 字元;cwd 在 `D:\...\阿鍚玉\分鏡\MMA纏鬥_快節奏...` 時存圖路徑 257 字元,超過 Windows 260 上限(本機 LongPathsEnabled=0)→「image_edit failed while saving」。**cwd 一律用短的英文路徑**(例如 scratchpad 子資料夾),參考圖也複製過去。
- **agy**:`C:\Users\capbair\AppData\Local\agy\bin\agy.exe` 1.3.5(Antigravity CLI),可選 Gemini 4 / Claude / GPT-OSS。直接工具沒有生圖,要交給內建 `image-generator` 子代理。`agy -p "<prompt>" --mode accept-edits --sandbox --print-timeout 900s`。約 78 秒,1376×768 JPG,圖存在 `C:\Users\capbair\.gemini\antigravity-cli\brain\<conversation>\*.jpg`,不會存到指定資料夾。
- **安全旗標**:`grok --always-approve`、`agy --dangerously-skip-permissions` 會被 Claude Code auto mode 分類器擋(Undermining Oversight)。改用上面只開生圖工具 / 只接受編輯的窄權限就能跑。
- 解析度都比 Codex(1672×941 PNG)低,但影片是 832×480,當首尾幀夠用。

相關:[[codex-on-161-via-ssh]] [[feedback-benchmark-against-previous-best]]
