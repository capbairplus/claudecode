---
name: comfyui-161-upgrade-0816
description: ".161 的 ComfyUI 於 2026-08-16 從 v0.18.2 升到 v0.33.1、LTX 2.3 檔案補齊,以及升級時必須保留的兩個本地修改與安全重啟方式"
metadata: 
  node_type: memory
  type: project
  originSessionId: b37f599c-ad07-48af-bb4a-5fffdf0b55b9
  modified: 2026-08-16T04:13:40.990Z
---

**2026-08-16 把 .161 的 ComfyUI 從 v0.18.2(2026-03-24)升到 v0.33.1(2026-08-13)**,並補齊 LTX 2.3
所需檔案。升級後 26 張卡的節點/參數全數驗證通過(唯一缺的是 ReActor,見下)。

**升級時絕對不能弄丟的兩個本地修改**(`git checkout` 會清掉,要事後補回):
1. `folder_paths.py` — ComfyUI-ArtGallery 的 `artists/cameras/films/movements/styles` 路徑註冊(5 段)。
2. `app/logger.py` — 把 `super().write()` / `super().flush()` 包 `try/except OSError: pass`。ComfyUI 跑在
   **SessionId 0 沒有 console**,少了這個保護重啟後很可能直接崩。上游 v0.33.1 仍未內建這個保護。

註:PowerShell 的 `git diff > x.patch` 會寫成 **UTF-16**,`git apply` 讀不懂("No valid patches in input")。
要備份就直接 `Copy-Item` 原檔,或改用 python 寫檔。

**安全重啟方式(不會在 chavi 螢幕上彈視窗)**:ComfyUI 由排程工作 `comfyui` 啟動(principal=chavi、
logon=**Password** → 跑在 Session 0;`cl.vbs` 以 hidden 模式呼叫 `comfyui-listen.bat`)。正確做法是
`Stop-Process` 掉舊 python,再 `schtasks /Run /TN comfyui`。
- ⚠ 不要用 `ReComfyui`(logon=**Interactive**,一定會出現在他螢幕上)。
- ⚠ 不要用 `WorkflowUI_ComfyUI_Restart` → `workflowui_restart.bat`:它的 `--output-directory`/
  `--input-directory` 寫成本機路徑,跟實際在跑的 `\\solisnas\solisftp\comfyui\{output2,input}` **不一致**,
  而且沒有先停舊 process。

**pip 注意**:`C:\ProgramData\pip\pip.ini` 設了 `extra-index-url = https://pypi.ngc.nvidia.com`,那個
host 現在 DNS 解不出來,會讓每次 pip 卡在 5 次 retry。加 `$env:PIP_EXTRA_INDEX_URL = ''` +
`--index-url https://pypi.org/simple` 就順了。pypi.org 本身通。

**升 core 後 custom node 會跟著壞**:ComfyUI-LTXVideo(4 月版)報
`cannot import name 'interleaved_freqs_cis' from 'comfy.ldm.lightricks.model'`,57 個 LTX 節點全部消失。
`git pull` 更新到 2026-08-11 版後恢復(105 個 LTX 節點)。升 core 後一定要用 `/internal/logs/raw` 掃
`IMPORT FAILED`,再用升級前的 `/object_info` 快照比對節點清單。

備份在 `D:\ComfyUI_backup_20260816_115126\`(patch、兩個 .bak、`pip_freeze_before.txt`)。

相關:[[video-card-pattern-and-reactor-gap]] [[workflowui-ltx23-card]] [[comfy-161-network-access]]
