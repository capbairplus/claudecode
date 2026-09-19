---
name: utilhub-deploy-canonical-repo
description: UtilHub (/util/) 正式原始碼只有 C:\wordpresscb\utilhub;唯一部署方式是該目錄的 deploy.ps1,G:\agy\util 是舊副本不可部署
metadata:
  type: project
---
UtilHub(capbairplus.duckdns.org/util/)所有工具都在同一支 UtilHub.exe。正式原始碼只有 `C:\wordpresscb\utilhub`(main 分支);部署只能用 `powershell -NoProfile -ExecutionPolicy Bypass -File C:\wordpresscb\utilhub\deploy.ps1`。

**Why:** 2026-09-19 從 G:\agy\util 執行 publish_restart.ps1 部署,覆蓋 publish 後線上 pdf-ocr、dual-agent API 全部 404(那份原始碼沒有它們)。

**How to apply:** 不要在 G:\agy\util 開發或執行其 publish_restart.*;改東西前先讀 C:\wordpresscb\utilhub\CLAUDE.md / AGENTS.md。白名單 AllowedLibraryRoots 在 publish\appsettings.Local.json。
