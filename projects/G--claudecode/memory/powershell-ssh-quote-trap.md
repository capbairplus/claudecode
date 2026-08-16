---
name: powershell-ssh-quote-trap
description: "用 PowerShell 直接串 ssh 遠端指令時內層引號會被吃掉,曾害 curl 的 -o 失效把 12GB 倒進本機暫存檔;改用 scp 腳本檔執行"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 6ea7b37a-af12-47e6-b0a7-b662e75955fe
  modified: 2026-08-16T07:41:43.315Z
---

**踩過的雷(2026-08-16,下載 Kontext 模型到 .161)**:用 PowerShell 工具寫
`ssh chavi@192.168.1.161 "curl.exe -sL -o `"$dst`" `"$url`""` 這種嵌套引號,
PowerShell 對 native command 的參數傳遞會**把內層引號吃掉**,遠端 curl 的 `-o` 沒生效,
於是 12GB 模型直接往 stdout 倒 —— 因為那是 `run_in_background`,實際是倒進本機的 task output 檔,
發現時已經寫了 3GB。同樣的引號問題也讓 `ssh ... "powershell -c \"Get-ChildItem D:\...\""`
回報「路徑不存在」,但用 cmd 的 `dir` 查同一個路徑明明就在——**別把這種假錯誤當成真的結論**。

**How to apply**:
- 要在 .161 上跑帶引號/長路徑的指令,**不要在 PowerShell 裡拼 ssh 指令字串**。
  寫成 `.cmd` 腳本 → `scp` 過去 → `ssh` 執行檔案路徑(單一 token,沒有引號問題)。
- 用 Bash 工具配**單引號**包遠端指令也可行(`ssh host 'dir /b D:\path\'`),比 PowerShell 穩。
- 長時間下載要把輸出重導到**遠端**的 log 檔(`> "D:\...\x.log" 2>&1`),ssh 那端只回 exit code,
  絕不能讓大量 stdout 流回本機背景任務檔。
- 下載中用 `.part` 副檔名,完成再 `ren` 掉——避免 ComfyUI 掃到半成品模型。

相關:[[comfy-161-network-access]] [[verify-before-claiming-unreachable]]
