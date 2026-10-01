---
name: utilhub-eval-20261001
description: 2026-10-01 UtilHub 評估後的修補與新功能已上線(main@170bf97);radio 權限收緊、sys-status 看板、Obsidian 存檔、雜誌搜尋;逐字稿功能因 .161 沒有中文 ASR 模型而未做
metadata:
  type: project
---
2026-10-01 使用者睡前授權「一路做到底」,對 `/util/` 評估並動工,**已用 deploy.ps1 部署上線(main@170bf97,17 個工具,298 .NET + 26 Python 測試全過)**。

已完成:
- **radio 安全**:原本整個 `/api/apps/radio` 免登入,`stream-proxy?url=http://127.0.0.1:5120/api/health` 能讀回內部回應(SSRF)。現在只有聽廣播的唯讀 API 公開(`Infrastructure/PublicAccess.cs`),寫入要登入、改電台目錄要 Admin;所有對外連線走 `PublicNetworkGuard`(連線當下擋 loopback/私網,轉址也擋);訪客只能代理電台目錄內的網址;錄音上傳 300 MB 上限 + 磁碟低於 3 GB 保留量就拒收;sync-state 綁登入帳號。Ollama service stop/start/restart 限 Admin;`/api/health` 對訪客隱藏內網資訊。
- **磁碟**:C: 7.7 → 19.1 GB。deploy.ps1 現在部署後只留最新 5 份備份、刪 staging、剩餘空間 <2 GB 拒絕部署;移除 22 個已合併 worktree。
- **新工具**:`sys-status`(.161 GPU/Ollama/ComfyUI/本機服務/磁碟/背景工作,SSH nvidia-smi 約 0.4 秒、快取 10 秒)、`magazine-search`(pdf-ocr 文章全文搜尋+Ollama 問答附出處;含未匯出的草稿期)。
- **Obsidian**:`/api/obsidian/save` 寫進 `D:\capbairvault\00 Inbox`(僅 Admin 或 `Obsidian:AllowedUsers`),dual-agent/ollama-query/novel-studio 有按鈕。
- 優化:radio 預設電台 23,700 行搬成內嵌 JSON(RadioStationService.cs 1.2 MB→95 KB)、garment-vocab 格式閘與整字統計修正(back 100%→21%)、manifest 補欄位、SshRunner 逾時會殺 ssh.exe。

**未做 / 待決定:**
- 廣播錄音逐字稿:.161 的 ComfyUI 有 whisper_local(llm_party,模型要從 HF 下載 openai/whisper-small)、Granite ASR(語言清單沒有中文)、Qwen3-TTS 引擎(本機只有 TTS 模型,沒有 ASR 模型);要做得先在共用 GPU 上裝/下載模型,沒在半夜動。
- deploy.ps1 的 `Remove-OldBuilds` 沒包 try/catch(那次編輯被權限擋下),萬一清理失敗會在部署成功後丟錯,不影響上線版本。
- 還沒寫進 Obsidian(使用者沒說 updateobsidian)。

**Why:** 之後接手要知道哪些已經修好、哪些是刻意沒做。
**How to apply:** 碰 UtilHub 先讀 [[utilhub-deploy-canonical-repo]];新增 radio API 預設就要登入(PublicAccess 白名單才公開);新增「根目錄」類設定要記得測試覆寫。
