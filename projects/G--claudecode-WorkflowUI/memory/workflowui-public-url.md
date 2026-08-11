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

C# 版的 manifest 系統是 Python 版的移植版,**新卡片/新機制要先在 Python 版做出來驗證過,再手動
移植到 C# 版**,不會自動同步,兩邊是分開維護的程式碼:

- `Models/ManifestModels.cs` ≈ Python `manifest_schema.py`
- `Services/ManifestLoader.cs` ≈ `manifest_loader.py`
- `Services/WorkflowEngine.cs` ≈ `workflow_engine.py`(`BuildJobs` ≈ `build_jobs`)
- `Program.cs` 的 `/api/generate` 端點 ≈ `routers/generate.py`
- `workflow_templates/<id>/` 資料夾結構完全一樣,manifest.json/workflow_api.json 可以直接複製過去

**C# 專案的 build/部署眉角**:
- 改完 `.cs`/`.csproj` 後要 `dotnet build`(在 `C:\wordpresscb\workflowui-csharp-poc\` 下跑),
  build 前要先 `taskkill //F` 掉正在跑的 `WorkflowUiCsharpPoc.exe`(不然檔案被佔用)。
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

## 進度

`pose_controlnet_flux`(角色 LoRA 姿勢批次生成卡,見 [[workflowui-pose-controlnet-card]])
2026-08-11 已經**兩邊都做好並各自驗證過真的能生成**:Python 版跟 C# 版都測試通過(C# 版直接打
`/api/generate` 送出、輪詢 `/api/jobs/{id}` 到 `status:done`,實際圖片檢查過姿勢/服裝/身份正常)。
之後任何新卡片都要記得比照這次的模式,兩邊都做,不要以為改 Python 版公開網址就會自動看到。

相關:[[workflowui-vision]] [[workflowui-deploy-192-168-1-35]] [[workflowui-pose-controlnet-card]]
