---
name: codex-on-161-via-ssh
description: .161 有 Codex CLI 0.165(chavi 的 ChatGPT 帳號、image_generation 開著),可 SSH 叫它畫圖;但 sandbox 寫不進工作資料夾,圖留在 generated_images 要自己 scp 回來
metadata:
  type: reference
---

2026-11-22 實測(阿鍚玉 MMA 關鍵幀):

- `ssh chavi@192.168.1.161` → `codex-cli 0.165.0`(`C:\Users\chavi\AppData\Roaming\npm\codex.cmd`),`codex login status` = Logged in using ChatGPT(額度算 chavi 那個帳號);`image_generation`、`view_image` 都是 true;config:`model = gpt-6-sol`、reasoning medium、`sandbox = "unelevated"`;全域 `AGENTS.md` 是「自動執行、不停下來問」。
- 工作資料夾放 `D:\ComfyUI_windows_portable\codex_jobs\<專案>\`(不要放 D:\ 根目錄)。用 `.cmd` 腳本 scp 過去再 ssh 執行(避開 PowerShell 引號陷阱,見 [[powershell-ssh-quote-trap]]),輸出重導到遠端 log。SSH 非互動執行,不會在 chavi 螢幕跳視窗。
- **雷**:`--sandbox workspace-write` 下 Codex **寫不進工作資料夾**(apply_patch「Failed to write file」、生成圖沒被存到指定路徑)。圖其實有生成,在 `C:\Users\chavi\.codex\generated_images\<session-id>\exec-*.png`,用 `scp` 抓回來即可。要讓它自己存檔得改 `danger-full-access`(在別人機器上解除 sandbox,要先問使用者)。
- **更根本的雷**:從 SSH 跑時 Codex 的 unelevated sandbox **連一個指令都開不了**(每個 exec 都 `exited -1073741502` = 0xC0000142 DLL 初始化失敗),所以**連讀委託 .md 都讀不到**,它會回「請把檔案貼給我」。解法:**不要叫它讀檔**,把委託書+規格+清單合併成一個 UTF-8 txt,用 `codex exec ... -C <dir> - -i a.png -i b.png < prompt.txt`(`-` 放在 `-i` 前面)從 stdin 餵;生圖與 view_image 是內建工具不受影響。叫它最後用固定格式回報 generated_images 路徑,再 scp 抓圖。
- 畫質與服裝一致性和本機 Codex 同級(同模型同生圖工具)。

相關:[[comfy-161-network-access]] [[feedback-benchmark-against-previous-best]]

**005（192.168.1.5，ssh 005）也有 Codex 0.165.0**（capbair 的 ChatGPT 帳號、生圖開著、sandbox = elevated；沒有 D 槽，工作夾用 `C:\Users\capbair\Documents\codex_jobs\<專案>\`）。2026-11-22 測試：elevated sandbox 從 SSH 起不了指令執行器（每次 15 秒逾時 `connecting runner pipe-in`），所以一樣存不進工作夾；圖在 `C:\Users\capbair\.codex\generated_images\<session>\exec-*.png`，1672×941 PNG，含逾時共 247 秒。007（192.168.1.7）沒裝 Codex。

**兩台通用的解法（2026-11-22 在 005 驗證，247 秒 → 57 秒，畫質不變）**：sandbox 模式換哪個都沒用（elevated 逾時、unelevated 0xC0000142，是 Windows sandbox 在 SSH 非互動 session 的限制），所以**乾脆不讓它跑指令**：`codex exec --skip-git-repo-check --sandbox read-only -C <dir> "<prompt>" -i <ref.png> < nul`，prompt 開頭明講「這台不能跑 shell、不能寫檔，不要跑任何指令、不要讀 skill/說明檔、不要存檔驗證，直接呼叫一次生圖工具，最後只回報生成檔路徑」。log 裡就不會再出現 exec / timed out。之後抓 `generated_images` 裡最新的 png 回來。
- ⚠ **一定要 `< nul`**(或 stdin 餵 prompt):沒關 stdin 的前景 ssh 呼叫,`codex exec` 會卡在「Reading additional input from stdin」不動。
- 005 上 session 2(使用者桌面的 Codex app)、session 0(服務)、以及 10/30 起就在跑的 session 3 codex/node 都不是我的,別去殺。
