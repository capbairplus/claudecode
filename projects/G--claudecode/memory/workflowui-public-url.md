---
name: workflowui-public-url
description: "WorkflowUI 對外公開網址(duckdns 反向代理)——背後是 C# 重寫版(port 8900),那才是主力版本,不是 G:\claudecode\WorkflowUI 的 Python 版(8899)"
metadata:
  node_type: memory
  type: reference
---

## 現況(2026-08-11,以此為準)

```
https://capbairplus.duckdns.org/comfyuicard/
```

**這是使用者指定以後給連結的預設/唯一首選**,不要給 localhost 或內部 IP,除非使用者明確要本機測試。
網域目前解析到公網 IP `122.116.82.127`(DuckDNS 動態 DNS,IP 會變,以網域名稱為準,需要時
`nslookup capbairplus.duckdns.org` 重查)。有 **HTTP Basic Auth 擋著(401)**,帳密使用者自己輸入,
不要猜測或繞過——連瀏覽器工具(mcp**Claude_Browser**)都連不到這台機器的內網,只能靠本機終端機
(curl/PowerShell)繞過 Apache 直接測後端本身,或請使用者自己在瀏覽器裡登入確認。

## 網域根目錄本身是 WordPress,底下掛好幾個反向代理的服務

`https://capbairplus.duckdns.org/` 首頁本身跑的是 WordPress(這台機器本地,`C:\wordpresscb\`,
DB 名稱 `capbairplus_wp`、DB user `capbair`、table prefix `cb_`,密碼在
`C:\wordpresscb\wp-config.php` 的 `DB_PASSWORD`,不寫入 memory)。用的是 Astra 佈景主題 +
Elementor。`php.exe` 在 `C:\php`,`mysql.exe` 在 `C:\mysql\bin`,兩者都能直接在本機終端機用。

`/comfyuicard/`、`/newsradar/` 都是掛在這個 WordPress 網域底下、各自獨立的服務,用 Apache
`ProxyPass` 轉發(設定都在 `c:\apache\conf\extra\httpd-ssl.conf`):
- `/comfyuicard/` → `127.0.0.1:8900`(C# 版 WorkflowUI,見下方)
- `/newsradar/` → `127.0.0.1:5299`(另一個專案,細節尚未探索過)

**改網站首頁的主選單(Appearance → Menus)不用登入 wp-admin GUI,直接改資料庫比較快**:
主選單是 `nav_menu` taxonomy 底下 `term_id=11`(名稱「CAPBAIRPLUS 主選單」,slug 顯示亂碼是
UTF-8 url-encode 過的中文,正常)。每個選單項目是一筆 `post_type='nav_menu_item'` 的
`cb_posts` row,搭配 `cb_postmeta`(`_menu_item_type=custom`、`_menu_item_url=<網址>`、
`_menu_item_object_id=<自己的 post ID>` 等)+ `cb_term_relationships`(把該 post 掛到
`term_taxonomy_id=11`)+ `cb_term_taxonomy.count` 要記得 +1。2026-08-11 已經照這個方式成功
新增「NewsRadar」「ComfyUI 卡片」兩個連結到主選單(post ID 2853/2854),用
`curl -k -H "Host: capbairplus.duckdns.org" https://localhost/` 從本機繞過 DNS/Basic Auth
直接驗證過渲染出來的 HTML 有新項目。改資料庫前先把相關 `cb_posts`/`cb_postmeta`/
`cb_term_taxonomy` 的既有內容 SELECT 出來存成備份檔,再動手。

## 架構:兩套獨立的 WorkflowUI 實作,只有一套是主力

- **C#/ASP.NET Core 版**(**主力,持續開發中**):`C:\wordpresscb\workflowui-csharp-poc\`
  (`WorkflowUiCsharpPoc.exe`,Kestrel `127.0.0.1:8900`)。這台機器本身跑著 Apache
  (`c:\apache`,Windows service `Apache2.4`),`/comfyuicard/` 是用 `ProxyPass` 轉發到這裡,
  設定檔 `c:\apache\conf\extra\httpd-ssl.conf`。
- **Python/FastAPI 版**(較舊,`G:\claudecode\WorkflowUI`,uvicorn `127.0.0.1:8899`):架構上是
  C# 版模仿的原型(manifest.json/workflow_api.json + ManifestLoader/WorkflowEngine 的設計都
  是先在 Python 版做的,C# 版照著搬),但**不是**公開網址背後實際在跑的東西。

**踩過的坑**:2026-08-11 一開始完全不知道 C# 版存在,誤以為公開網址就是 Python 版,還一度把
Apache 的 `ProxyPass /comfyuicard/` 從 8900 改到 8899(方向錯了),被使用者指正「C# 是新的」
後改回 8900。**結論記住:C# 版是主力,Python 版是舊的/開發用的,公開網址永遠是 C# 版。**

## 兩套怎麼保持同步

⚠ **這段的「先 Python 再移植」已作廢**(2026-08-18,見 [[workflowui-csharp-only]]):**新卡片與新
機制一律直接做在 C# 版**,Python 版不再跟進。以下的對照表仍然有效,拿來查兩邊哪個檔案對應哪個。

C# 版的 manifest 系統是 Python 版的移植版,兩邊是分開維護的程式碼、不會自動同步:

- `Models/ManifestModels.cs` ≈ Python `manifest_schema.py`
- `Services/ManifestLoader.cs` ≈ `manifest_loader.py`
- `Services/WorkflowEngine.cs` ≈ `workflow_engine.py`(`BuildJobs` ≈ `build_jobs`)
- `Program.cs` 的 `/api/generate` 端點 ≈ `routers/generate.py`
- `workflow_templates/<id>/` 資料夾結構完全一樣,manifest.json/workflow_api.json 可以直接複製過去

**C# 專案的 build/部署眉角**:
- 改完 `.cs`/`.csproj` 後要 `dotnet build`(在 `C:\wordpresscb\workflowui-csharp-poc\` 下跑),
  build 前要先 `taskkill //F` 掉正在跑的 `WorkflowUiCsharpPoc.exe`(不然檔案被佔用)。
- **2026-08-16 起已經改成 Windows Service,不用再手動跑 exe**:服務名稱
  `WorkflowUiCsharpPoc`,`start= auto`(開機自動啟動)+ `sc failure` 設定意外結束自動重啟
  (5 秒後重試,連續 3 次,24 小時重置計數)。踩過的坑:`Program.cs` 原本沒有
  `builder.Host.UseWindowsService()`,直接 `sc create` 指到 exe 會因為收不到 SCM 的
  「已啟動」回報而失敗,補了這行 + `Microsoft.Extensions.Hosting.WindowsServices` 套件才能用
  `sc create`/`sc failure`/`sc start` 正常註冊。`sc create` 需要系統管理員權限,Claude Code
  的終端機不是提權執行,這三行 `sc.exe create/failure/start` 只能請使用者自己在提權
  PowerShell 跑;另外 `sc.exe` 的 `binPath=` 引數如果要在裡面包含空白的路徑,PowerShell
  不能用 cmd.exe 的 `\"..\"` 跳脫法(`\"` 在 PowerShell 裡會提前把字串斷開,`sc create` 只
  會印出 usage 說明,不會真的執行),要用一般雙引號包住整個值就好(這個 exe 路徑本身沒有
  空白,所以其實不用內層引號)。之後改完程式碼重新 build 完,要記得
  `sc.exe stop WorkflowUiCsharpPoc` 再 `sc.exe start WorkflowUiCsharpPoc`(或直接
  `Restart-Service`)讓新 build 生效,不用再 `taskkill` + 手動跑 exe 了。
- **`workflow_templates/**/*.json` 以外的資產(例如新卡片自帶的 PNG 骨架圖、`wwwroot/` 前端檔案)
  不會自動複製到 `bin/Debug/net8.0-windows/` build 輸出目錄**,要在 `.csproj` 補
  `<Content Update="路徑\**\*.副檔名"><CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory></Content>`
  ——用 `Update` 不要用 `Include`(這些檔案其實已經被 SDK 預設當成 Content item 了,`Include`
  會撞成 `NETSDK1022` 重複項目錯誤,只是預設沒有複製到輸出目錄的 metadata,`Update` 才是正確補法)。
  wwwroot 靜態檔案沒複製到輸出目錄時,ASP.NET Core 在 Production 環境下會整個 404(`UseStaticFiles()`
  的 static-web-assets 便利機制只在 Development 生效),不是小問題,遇到「首頁打不開/前端消失」
  先檢查這個。
- build 完重啟:`cd bin\Debug\net8.0-windows` → `.\WorkflowUiCsharpPoc.exe --urls http://127.0.0.1:8900`。
  這台機器本身開著,Claude 有完整權限重啟,不像 1.35 那樣需要對方 sudo 密碼。
- appsettings.json 的 `Storage:AllowedRoot`(預設 `output`,相對於 exe 所在目錄)是 `/api/generate`
  寫入結果的白名單根目錄,跟 Python 版的 `ALLOWED_PROJECT_ROOTS` 是不同機制,兩邊各自獨立設定。

## 輸出路徑:C# 版寫不到 G:\claudecode\output(2026-08-20 實測結論)

**C# 版的輸出根目錄是 `appsettings.json` 的 `Storage:AllowedRoot` = `C:\wordpresscb\workflowui-output`,
跟 Python 版的 `G:\claudecode\output` 是完全不同的機制**,而且**不能改成 G:**:

- 服務以 **LocalSystem** 執行,**磁碟機代號是 per-user 的**,服務的 session 裡沒有 `G:`。
  實測用服務自己的 `/api/style-library`(它會以服務身分 `Directory.Exists`)探測:
  `G:\claudecode` 回 **404「is not a directory」**,但同一路徑在使用者 session 下完全正常。
- 改用 UNC 也不行:把 `AllowedRoot` 設成 `\\192.168.10.28\g\claudecode\output` 重啟後,health 回
  **`UnauthorizedAccessException: Access to the path ... is denied`**,自動 fallback 回本機路徑。
  原因是 LocalSystem 連網路分享時是用**電腦帳號 `CAPBAIR31$`** 認證(這台機器是 CAPBAIR31 /
  192.168.3.31,`G:` 對應 `\\192.168.10.28\g` 是另一台機器的分享),那邊沒開權限給它。
- 要真的改成共用位置,只有兩條路:(a) 在 192.168.10.28 上把分享/NTFS 權限開給 `CAPBAIR31$`;
  (b) 用 `sc config obj=` 把服務改成以使用者帳號執行(要密碼 + 提權)。**兩者都還沒做。**
- **程式有安全網**:建目錄失敗會自動退回 `FallbackRoot` 並在 `/api/health` 的 `storage_warning` 報出來,
  服務不會掛。但注意 fallback 只在「建目錄失敗」時觸發,「讀得到但寫不進去」要等實際生成才會爆。

**連帶影響**:`political_cartoon_flux` 的 `categories_source` 指向 `G:\claudecode\政治漫畫\styles`,
**服務讀不到,所以公開網址上那張卡的風格選單是空的**(`/api/cards/political_cartoon_flux` 的
`categories` = 0 筆)。Python 版正常因為它以使用者身分跑。要修得把該 manifest 的路徑改成 UNC,
但前提是上面的權限問題先解決。

## 進度

`pose_controlnet_flux`(角色 LoRA 姿勢批次生成卡,見 [[workflowui-pose-controlnet-card]])
2026-08-11 已經**兩邊都做好並各自驗證過真的能生成**:Python 版跟 C# 版都測試通過(C# 版直接打
`/api/generate` 送出、輪詢 `/api/jobs/{id}` 到 `status:done`,實際圖片檢查過姿勢/服裝/身份正常)。
之後任何新卡片都要記得比照這次的模式,兩邊都做,不要以為改 Python 版公開網址就會自動看到。

`caricature_qwen`(人物轉卡通/政治漫畫人物,見 [[workflowui-caricature-card]])2026-08-12 同樣
兩邊都做好並各自對真 .161 驗證過。另外注意:**C# 版 exe 開機不會自動啟動**,那天發現 8900 完全
沒在 listen(公開網址那條路徑等於 502),是手動
`Start-Process ...\WorkflowUiCsharpPoc.exe --urls http://127.0.0.1:8900 -WindowStyle Hidden`
起來的——之後使用者說「公開網址打不開」,先查這支 exe 在不在。

`minimax_h3_{t2v,i2v,flf2v,r2v}`(見 [[workflowui-minimax-h3-cards]])2026-08-18 兩邊都做好。
**又踩了同一個坑**:先只做 Python 版,使用者問「我怎麼沒在公開網址看到這張卡」才發現漏了移植。
這次學到的新細節:**移植純 manifest 卡片不需要 `dotnet build`、也不需要重啟服務**——
`ManifestLoader.LoadCards()` 是每次請求重掃目錄,只要把資料夾同時複製到
`workflow_templates\`(原始碼,給之後 build 用)和 `bin\Debug\net8.0-windows\workflow_templates\`
(服務實際讀的),`/api/cards` 立刻就會多出來。要 build 的只有改 `.cs` 或加非 JSON 資產時。

`ltx23_t2v` / `ltx23_t2v_hq` 也在 2026-08-18 一起搬過去並在 C# 版各跑一支確認(225 秒 / 285 秒)。
2026-08-19 01:15 使用者跑完提權重建後 **C# 版變 46→47 張、Python 版停在 41 張**(C#-only 決定之後
Python 落後是預期的)。多出來的是別的 session 直接做在 C# 版的卡:`animatediff_sd15`、
`controlnet_compose_flux`、`txt2img_anime`、`txt2img_sdxl`、`txt2img_zimage`。
⚠ **它們原本只寫進原始碼的 `workflow_templates\`、沒複製到 `bin\Debug\net8.0-windows\`,
所以一直沒上線,是我這次 rebuild 才連帶推上公開網址的**(build 會把 Content 複製過去)。
教訓:做完卡片一定要兩個目錄都放,否則會累積一批「檔案在、線上沒有」的卡,之後被別人的
rebuild 意外一次推上線。

**C# 版的 group 已於 2026-08-18 補上**(index 摺疊 + card.html 的模式 select),改了三處:
`Program.cs` 的 `/api/cards` 列表 DTO 補 `group`/`group_label`(原本只回 id/title/description/
category/status,前端根本拿不到 group)、`wwwroot/index.html` 加 `collapseGroups()`/`groupEntry()`
(照抄 Python 版 index.html 的做法,群組連到 `card.html?group=...`)、`wwwroot/card.html` 把 init()
裡「載入 manifest + 建表單」抽成 `loadCardForm(id)` 並加 `renderGroupSwitch()`(`cardId` 從 `const`
改 `let`,submit handler 只註冊一次、送出時讀當下的 `cardId`)。`app.js` 的 `CARD_ICONS` 同時補了
6 張新卡與 7 個群組 key 的圖示(群組 tile 用 group key 查圖示)。摺疊後首頁從 41 張變 30 個 tile。

**同時新增 `group_order`(兩邊都有)**:manifest 的選填整數,決定群組裡哪張先開、下拉怎麼排;
沒填的排最後、維持原本順序,所以既有群組(換臉、放大、Wan)行為不變。Python 端動
`manifest_schema.py`+`routers/cards.py`+`frontend/{index,card}.html`,C# 端動
`Models/ManifestModels.cs`+`Program.cs`+`wwwroot/{index,card}.html`。已設定:
`minimax_h3_t2v/i2v/flf2v/r2v` = 1/2/3/4、`ltx23_t2v`/`ltx23_t2v_hq` = 1/2。
順手修掉 Python `frontend/card.html` 把模式下拉的 label 寫死成「換臉方法」的問題(掛在 MiniMax
卡上會顯示錯字),改成中性的「模式」,跟 C# 版一致。

**Python 版(8899)改到 `.py` 要重啟才生效**(manifest 是每次請求重掃,但 schema/router 是啟動時
載入的):`taskkill //F //PID <8899 的 pid>` 之後 `cmd //c start "" //min run_hidden.vbs`,約 8 秒起來。

**兩個部署踩到的雷**:
1. **`sc.exe stop` / `Stop-Service` 需要提權**,Claude Code 的終端機不是提權執行(回「存取被拒 5」),
   所以**改 `.cs` 後的 build+重啟只能請使用者在系統管理員 PowerShell 跑**:
   `Stop-Service WorkflowUiCsharpPoc; dotnet build <csproj> -c Debug; Start-Service WorkflowUiCsharpPoc`。
   純 manifest 卡片複製則完全不用碰服務。
2. **驗證新 build 不必碰正式服務**:`dotnet build -o <暫存目錄>` 出一份(Content 規則會一併複製
   `workflow_templates` 與 `wwwroot`),再用**環境變數**換埠跑起來測。⚠ `--urls` 沒有用——
   `appsettings.json` 的 `Kestrel:Endpoints:Http:Url` 會蓋掉它(log 會出現 "Overriding address(es)"
   然後撞埠失敗),要用 `Kestrel__Endpoints__Http__Url=http://127.0.0.1:8901` 這種環境變數才換得掉。

**原本的狀況(已修)**:C# 前端沒有實作 group:`wwwroot/app.js` 裡完全沒有 group 相關程式碼,所以 `minimax_h3_video`、
`ltx23_video`、`faceswap` 這些群組在公開網址上都是各卡分開列(Python 版才會收成一張用 select 切換)。
另外 `app.js` 的 `CARD_ICONS` 按 card id 對應圖示,沒對應到的卡 fallback 成通用 image 圖示——新搬過去
的 6 張影片卡目前都是那個圖示。兩者都不影響功能。

相關:[[workflowui-vision]] [[workflowui-deploy-192-168-1-35]] [[workflowui-pose-controlnet-card]] [[workflowui-minimax-h3-cards]]
