---
name: windows-tooling-gotchas
description: 在 capbair31 上動工具時踩過的三個雷：沙箱寫入看不到、heredoc 吃反斜線、Compress-Archive 路徑分隔符
metadata:
  node_type: memory
  type: project
  originSessionId: 9c9082d5-3f8a-4ab2-8852-b75da1a16347
  modified: 2026-11-18T17:18:57.201Z
---

在 capbair31（192.168.3.31）這台機器上做檔案與打包工作時踩過的雷：

1. **沙箱寫入不會進到使用者看得到的磁碟。** 一般的 Bash/PowerShell 呼叫跑在沙箱裡，`Copy-Item` 到 `%LOCALAPPDATA%` 會被重導到 `C:\Users\capbair\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\`。我在沙箱內檢查會「成功」，使用者的檔案總管卻看不到檔案，等於謊報完成。**凡是使用者要親眼看到、或要自己執行的檔案操作（安裝、複製安裝包），一律加 `dangerouslyDisableSandbox: true`，並在沙箱外重新驗證一次。**

2. **Bash heredoc 會把 `\\` 吃成 `\`。** 用 `cat > file <<'EOF'` 寫含 Windows 路徑或正規表示式的 JS/Python，即使引號括住分隔符仍會被處理，產生 `"D:\Book"` 這種壞字串（JS 會報 octal escape 錯誤）。**內容含反斜線時改用 Write/Edit 工具，不要用 heredoc。** 這個雷踩過兩次。

3. **Windows PowerShell 5.1 的 `Compress-Archive` 用反斜線當 zip 路徑分隔符。** 產生的 zip 拿到 macOS/Linux 解壓，會變成檔名裡含反斜線的壞檔案。**要給非 Windows 用的 zip 改用 Python `zipfile`**（順便能用 `external_attr` 設 `.sh` 的執行權限）。

另見 [[screencapture-browser-extension]]。
