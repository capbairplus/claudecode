---
name: comfy-161-model-download-path
description: "往 .161 放大模型檔一律 SSH 進去就地 curl(20MB/s),不要本機下載再走 SMB(5.5MB/s)或直接寫網路磁碟(370KB/s);另:別用 Invoke-WebRequest 測速"
metadata:
  node_type: memory
  type: project
  modified: 2026-09-04T00:40:00.000Z
---

**要把大模型檔放到 .161(`D:\ComfyUI_windows_portable\ComfyUI\models\...`),
一律 SSH 進去用 `curl.exe` 就地下載。** 2026-09-04 抓 MiniMax Music 3 的 14.3GB 時實測:

| 做法 | 速度 | 9.2GB 要多久 |
|---|---|---|
| 本機 curl 直接寫進 `\\192.168.1.161\d\...`(SMB) | 370 KB/s | ~7 小時 |
| 本機下載到 C 槽 → `cp` 到 SMB 分享 | 下載 10.5 MB/s、**複製只有 5.5 MB/s** | ~28 分鐘 |
| **SSH 到 .161 用 `curl.exe` 直接抓** | **20 MB/s** | **~7.7 分鐘** ✅ |

瓶頸是**寫入網路磁碟**那段,不是對外頻寬(H3 那 44GB 當初也是 28MB/s 抓下來的)。

指令長這樣(注意是 `curl.exe`,不是 PowerShell 的 curl alias):
```
ssh -o BatchMode=yes chavi@192.168.1.161 "curl.exe -L --retry 5 -o \"D:\\...\\xxx.safetensors.part\" <url>"
ssh -o BatchMode=yes chavi@192.168.1.161 "move /Y \"D:\\...\\xxx.part\" \"D:\\...\\xxx.safetensors\""
```

**⚠ 三個踩過的坑:**

1. **不要因為 `appsettings.json` 裡那把金鑰讀不到就放棄 SSH。**
   `C:\wordpresscb\workflowui-csharp-poc\svc_id_ed25519_161` 的 NTFS 權限只給 C# 服務的帳號,
   一般 session 讀不到也 `cp` 不出來(`Permission denied`)。但**裸連 `ssh chavi@192.168.1.161`
   不指定 `-i` 就通了**。先試裸連再說。呼應 [[comfy-161-network-access]]:SSH 是穩定備援。

2. **⚠ 絕對不要用 `Invoke-WebRequest` 量下載速度。** PowerShell 5.1 的它會做 HTML 解析與進度條
   渲染,大檔案慢十倍:同一個檔案 `Invoke-WebRequest` 測出 1.5 MB/s、`curl.exe` 測出 16 MB/s。
   我當時據此下結論「.161 對外頻寬很慢,SSH 下載不划算」——**完全錯誤,而且手上明明就有反證**
   (H3 44GB / 28MB/s 的紀錄),卻沒去對照就把錯結論講得很篤定,使用者直接回「聽你在放屁」。
   **測出來的數字跟已知事實矛盾時,先懷疑測量方法,不要先改結論。** 見 [[feedback_verify_before_answering]]。

3. 中斷正在跑的 SMB 複製要連 `/usr/bin/cp` 跟它的父 shell 一起 kill,再手動清 `.part` 殘檔。

**驗檔**:下載完比對 `content-length`(`curl -sI -L <hf-url>`)跟落地檔案大小。
檔案放進 models 目錄後 **ComfyUI 不用重啟**,`/object_info` 立刻查得到。

相關:[[comfyui-161-upgrade-0816]] [[comfy-161-network-access]] [[workflowui-minimax-music3-card]]
