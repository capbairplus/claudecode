---
name: delegate-remote
description: >-
  用 SSH 把交接規格交給遠端電腦（192.168.1.161 = chavi、192.168.1.5 = 005）上的 codex 執行。額度快用完、
  或使用者說「交給 161/005 的 codex」「用 ssh 的 codex 做」、或工作需要那台機器的資源時使用。由 delegate skill 呼叫。
  腳本 run_remote.ps1 上傳規格 → 遠端 codex exec → 拉回報告;全程不會在遠端螢幕開視窗。
---

# delegate-remote:SSH 遠端 codex(161 / 005)

## 先看這些限制
1. **遠端的檔案系統和這台不共用。** 遠端 codex 看不到 `D:\`、`G:\`。規格要用的檔案必須用 `-Upload` 上傳(資料夾會整個上傳);成果放遠端 `out\`,腳本結束後自動拉回。**大檔(模型、資料庫、數 GB)不要上傳**,這種工作改在本機做或請使用者手動搬。
2. **那台電腦可能有人坐在前面用,或正在跑 LoRA 訓練/ComfyUI。** 這是使用者全域規則:**絕不能讓 cmd/PowerShell 視窗出現在對方螢幕**。腳本讓 codex 直接在 SSH 行程裡跑(不用 `schtasks`、不用 `Start-Process`),`rules_zh.md` 也禁止代理開視窗、殺程序。交辦前先問使用者「現在那台有人在用嗎/在訓練嗎」。
3. **不要用查 `MainWindowHandle` 之類的方法驗證「有沒有視窗」**:SSH session 與對方互動 session 隔離,查不到不代表沒有。
4. 工作目錄在遠端 `%USERPROFILE%\delegate_jobs\<jobid>\`,**不碰磁碟根目錄**。結束後留著,問使用者要不要刪。

## 啟動(Claude 用 run_in_background 跑)
```powershell
powershell -NoProfile -File "$env:USERPROFILE\.claude\skills\delegate-remote\run_remote.ps1" `
  -HostAlias 161 -Spec D:\專案資料夾\SPEC_xxx.md [-Upload <檔案或資料夾1>,<2>] [-Model <模型>] [-Full] [-TimeoutMin 120]
```
- `-HostAlias` 用 `~/.ssh/config` 的別名:`161`(chavi)、`005`(capbair)、也可 `003 006 007 035 126 158 167`(**這幾台未測試,codex 不一定有裝**)。
- 拉回本機:`<規格資料夾>\_delegate\<jobid>_ssh<主機>\` 內有 `REPORT.md`、`out\`、`run.log`、`last_message.txt`。
- 使用者手動跑(不耗 Claude 額度)就是上面這行。

## 各主機實測狀況(2026-11-22,codex-cli 0.165.0)
| 主機 | 預設沙盒 `-s workspace-write` | 備註 |
|---|---|---|
| **161**(chavi) | ✅ 通過(140 秒) | 有 git、Python 3.10/3.11/3.12 |
| **005**(capbair) | ❌ **失敗**:沙盒執行器逾時 `connecting runner pipe-in timed out`,讀寫全被擋,代理自己回報 BLOCKED | 有 git、Python 3.13/3.14。**`-Full`(關沙盒)尚未驗證**,需使用者同意後才可試 |

- 原因推測:codex 的 Windows 沙盒需要互動式 session 才起得來,SSH 非互動連線下在 005 失敗、在 161 正常;**根因未確認**,不要當成定論。
- `-Full` = `--dangerously-bypass-approvals-and-sandbox`:代理能動遠端任何檔案。只有使用者同意、規格範圍明確、遠端沒有重要檔案風險時才用。

## 踩過的雷
- PowerShell 5.1 + `$ErrorActionPreference='Stop'`:`scp` 抓不到遠端檔案(例如代理沒寫 REPORT)時,stderr 會變成終止錯誤、整個腳本中斷。拉回階段已改 `Continue`。
- 中文提示詞不要放在 ssh 命令列(編碼會壞):腳本把提示詞存成 UTF-8 檔、用 `codex exec … - < PROMPT.md` 從 stdin 餵給遠端,命令列保持 ASCII。
- 遠端預設 shell 是 cmd(不是 PowerShell),指令要用 cmd 語法(`&` 串接、`%USERPROFILE%`)。
- 遠端 `run.log` 以 UTF-8 寫入,用 `powershell -Command "Get-Content … -Encoding UTF8"` 看才不會亂碼。
