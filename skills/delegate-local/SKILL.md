---
name: delegate-local
description: >-
  把交接規格（SPEC）交給「這台電腦」上的 AI 代理執行:codex、grok、agy（Antigravity）。額度快用完、或使用者說
  「交給 codex/grok/antigravity/agy 做」時使用。由 delegate skill 呼叫,也可單獨用。啟動腳本 run_local.ps1 在背景執行、不開新視窗,
  跑完印出 REPORT.md 前 10 行。
---

# delegate-local:本機代理（codex / grok / agy）

先用 `delegate` skill 寫好規格（`SPEC_*.md`）。**規格放專案資料夾,不要放磁碟根目錄。**

## 啟動(Claude 用 run_in_background 跑)
```powershell
powershell -NoProfile -File "$env:USERPROFILE\.claude\skills\delegate-local\run_local.ps1" `
  -Agent codex -Spec D:\專案資料夾\SPEC_xxx.md [-Cwd <工作目錄>] [-Model <模型>] [-AddDir <路徑1>,<路徑2>] [-Full] [-TimeoutMin 120]
```
- 輸出放在規格旁的 `_delegate\<時間>_<代理>\`:`PROMPT.md`、`run.log`、`run.err.log`、`REPORT.md`(代理寫的)、`last_message.txt`(codex)。
- 腳本會自動把 `delegate\rules_zh.md` 和規格路徑寫進提示;代理被要求在 `REPORT.md` 前 10 行放摘要。
- **使用者自己手動跑**(完全不用 Claude 額度)就是上面這行,貼到自己的終端機即可。

## 各代理差異(2026-11-22 實測,cli 版本 codex 0.163 / grok 1.0.89 / agy 1.5.14)
| | codex | grok | agy |
|---|---|---|---|
| 呼叫 | `codex exec -C <cwd> -s workspace-write --add-dir … -o last_message.txt` | `grok --cwd <cwd> --always-approve -p …` | `agy --dangerously-skip-permissions --model … -p …` |
| 預設模型 | gpt-6-sol(來自 ~/.codex/config.toml) | grok-4.7 | 腳本預設 gemini-4-neon-high(CLI 預設是較弱的 Gemini 3.8 Flash) |
| 權限 | 沙盒 workspace-write,只能寫 `-Cwd` 與 `-AddDir`;`-Full` = 關沙盒 | 一律自動核准 | 一律自動核准 |
| 額外目錄 | `-AddDir` 可用 | **不支援**(`-p` 模式會報錯),`-Cwd` 必須是共同上層資料夾 | `-AddDir` 可用 |
| 冒煙測試耗時 | 89 秒 | 185 秒 | 84 秒 |

- 其他可用模型:`agy models`(含 claude-opus-5-5-high、gemini-4-neon-xhigh);`grok models`(grok-4.7、grok-4.7-build-fast、grok-4.6…)。
- 超時(預設 120 分鐘)會砍掉整個行程樹並印出 TIMEOUT。
- 想看代理做到哪:`Get-Content <jobdir>\run.log -Tail 30`;不要頻繁輪詢(浪費 Claude 額度)。

## 踩過的雷
- grok `-p` + `--add-dir` → `additionalDirectories is not supported: a session works only in its cwd`,3 秒就退出、沒有報告。腳本已改成不帶 `--add-dir` 並警告。
- `Start-Process -PassThru` 的 `ExitCode` 會是空的,要先 `$null = $p.Handle`。已修。
- 終端機顯示中文變亂碼只是主控台編碼(cp950),檔案本身是 UTF-8,用 `Get-Content -Encoding UTF8` 讀。
- 代理是自動核准一切:規格要寫「不准做的事」,輸出要用新版號;重要檔案要先備份(`rules_zh.md` 已要求,備份檔名帶代理代號)。
