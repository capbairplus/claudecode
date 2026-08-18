---
name: solis-news-aggregator-ollama-conflict
description: NewsRadar(Solis News Aggregator)的 WP-Cron 排程會把 ollama qwen3:8b 鎖在 .161 的 GPU 上,拖垮同機的 ComfyUI
metadata:
  type: project
---

**`.161` 上持續呼叫 ollama、把 GPU 佔住的元凶是 NewsRadar**,不是 WorkflowUI(2026-08-17 查出)。

`Solis News Aggregator` 是掛在 `capbairplus.duckdns.org/newsradar/` 的 WordPress 外掛(反代到
`127.0.0.1:5299`),它的 `Parser/OllamaAnalyzer.php` 打的是 **`192.168.1.161:11434` 的 `qwen3:8b`**
——跟 WorkflowUI 的 `llm_expand` 是同一個 ollama、同一個模型。關鍵在 `Scheduler/NewsCron.php` 的
**WP-Cron 排程**:定期抓 RSS,每篇文章都送去分析相關性,一跑就是一批,`keep_alive` 被連續續期,
6GB 顯存長期不放。實際監看 `ollama ps` 9 分半,「4 minutes from now」倒數從來沒有動過。

**後果**:同機 ComfyUI 上需要大顯存的卡會擠不進去,而且**不會報錯**——ComfyUI 降級成把權重留在
系統記憶體、每步搬進搬出,LTX 2.3 影片卡因此從每步 10.6 秒變成 350–400 秒(慢 33 倍)卻仍顯示成功。
連只剩 2.2GB 殘留都會讓 `ltx23_t2v_hq` 從 354 秒變成 617 秒。

**✅ 已修好並部署到正式站**(2026-08-17,原始碼在 `G:\claudecode\Solis Website\wordpress\plugins\solis-news-aggregator`):

- `Parser/OllamaAnalyzer.php` 新增 `release()`,對 `/api/generate` 送 `{model, keep_alive: 0}`。
  實測回傳 `{"done":true,"done_reason":"unload"}`,ollama 明確回報已卸載。best-effort、不拋錯。
- `Parser/ContentAnalyzer.php` 新增 `release()`,遍歷 providers 只對 `OllamaAnalyzer` 呼叫
  (沒加進 `AnalyzerInterface`——DeepSeek 是無狀態雲端 API,沒東西要釋放)。
- `Scheduler/NewsCron.php` 的 `run()` 把整個 foreach 包進 `try`,在 **`finally`** 裡呼叫
  `$analyzer->release()`,確保中途出錯也不會把顯存卡住。

**關鍵設計:不要照抄 WorkflowUI 的做法**。WorkflowUI 是單次互動,`analyze()` 每篇文章呼叫一次,
若逐篇帶 `keep_alive: 0`,一批 N 篇就要重載模型 N 次。正確做法是**批次內保持載入(快),批次結束
釋放一次**。

已驗證:三個檔案 `php -l` 通過;**所有入口都走 `NewsCron::run()`**(WP-Cron、WP-CLI 的
`FetchCommand`、後台 `SettingsPage` 的兩個 Fetch 按鈕、主外掛檔),所以 `finally` 涵蓋每條路徑。

**⚠ 部署時發現:`G:` 的原始碼落後正式站 10 個檔案**——正式站多了 `Identity\`、`Progress\`、
`Editorial\`、`Fetch\`、`FeedParser`、`RoundRobinCandidates`、`InsightSort`、`tests\`,連
`NewsCron::run()` 都已改成回傳統計報告 + 收 `ProgressTracker` 參數。**當初那句
`scp -r ... plugins/` 如果成功了,會靜默刪掉去重、進度追蹤、抓取報告等功能**(WordPress 不報錯,
只會悄悄退化)。使用者實際跑那行時因為 `G:` 在提權視窗看不到而失敗,反而躲過一劫。

處理:備份 `G:` 舊版(`plugins\solis-news-aggregator.bak_20260817`)→ 用正式站版本覆蓋 `G:`
(先確認 `G:` 沒有任何正式站缺少的檔案)→ 在新版上重做三處改動 → 逐檔 scp。正式站三個檔案也各留
`.bak_20260817`。

**未來的部署流程已固定成 `DEPLOY.md`**,放在原始碼根目錄(刻意不部署到正式站):先拉正式站回來
`diff -rq` 確認沒落後 → 在新版上改 → `php -l` → 遠端備份 → **逐檔 `scp`、永遠不要 `-r`** →
正式站驗語法 + `wp-cli eval-file` 驗路徑。
⚠ 別拿 `wp-cli.phar solis-news-aggregator fetch` 當煙霧測試——它會真的建立草稿文章。

**已驗證**:本機與正式站各跑一次 `php -l`;用 `wp-cli eval-file` 在真實 WordPress 環境實際呼叫過
`ContentAnalyzer::release()` 與 `OllamaAnalyzer::release()`,皆無錯誤;縮排改動用「忽略縮排後比對」
確認只新增 8 行、原邏輯一行沒動。

另一個更徹底的選項是在 `.161` 設 `OLLAMA_KEEP_ALIVE=0` 或 `OLLAMA_NUM_GPU=0`(全域生效、
不管誰呼叫),但那要動 chavi 機器上的服務設定。

vault 筆記:`D:\capbairvault\new soliswebsite\Solis News Aggregator.md`(已在該篇檔尾補上
「關聯筆記」段落說明這個衝突,並回連 WorkflowUI 那篇)。

相關:[[comfy-161-shared-machine-gpu]] [[workflowui-ltx23-card]] [[workflowui-public-url]]
