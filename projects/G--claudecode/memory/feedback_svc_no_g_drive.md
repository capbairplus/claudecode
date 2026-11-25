---
name: svc-no-g-drive
description: svc (SvcControl) 專案所有檔案/備份/文件一律放 D:\myproject\svc,不要用 G:
metadata:
  type: feedback
---

svc 相關檔案(備份、文件、腳本)一律放 `D:\myproject\svc`,不要再用 G: 存取。

**Why:** 以系統管理員(UAC 提升)開的 PowerShell 看不到 G: 槽(2026-11-25 update_svccontrol.ps1 因 `G:\Codex\output\svc-process-control` 備份路徑失敗)。已把 G:\Codex\output\svc-process-control 的舊備份搬到 `D:\myproject\svc\_backup\svccontrol`。

**How to apply:** 為 svc 寫腳本/備份/輸出時,路徑用 D:;需要管理員權限執行的腳本尤其不可依賴 G:。
