---
name: apache-letsencrypt-renewal-failure-1002
description: 2026-10-01 capbairplus 憑證過期導致網站打不開——win-acme 每天續期都失敗的三個根因與修法;續期後 Apache 不會自動重載
metadata:
  type: project
---

**現象**:2026-10-02 `https://capbairplus.duckdns.org/comfyuicard/` 打不開。WorkflowUI 服務、8900、Apache 都正常,
curl 顯示 `SEC_E_CERT_EXPIRED`——Let's Encrypt 憑證 10/1 12:36 GMT 到期。上次成功續期是 7/3(mycbas 是 7/18)。

**win-acme(`C:\win-acme`,renewal 設定在 `C:\ProgramData\win-acme\acme-v02...\*.renewal.json`)每天都在跑但都失敗**:
1. capbairplus 的 FileSystem 驗證 webroot 是 `C:\cbwordpress`,但 Apache port 80 vhost 把
   `/.well-known/acme-challenge/` Alias 到 `C:/wordpresstemp/...` → 路徑對不上。已把 renewal json 改成 `C:\wordpresstemp`。
2. 兩個網域都回 403:`C:/wordpresstemp` 是 `AllowOverride All`,WordPress `.htaccess` 的 `RewriteEngine On`
   會套到 challenge 目錄,而那個 `<Directory>` 是 `Options None` → `AH00670` 禁止重寫 → 403。
   修法:放 `C:\wordpresstemp\.well-known\.htaccess`(`RewriteEngine Off`),不用重啟 Apache 就生效。
3. renewal 的 InstallationPluginOptions 是 None,**續期成功也不會重載 Apache**——要手動 `Restart-Service Apache2.4`(需管理員)。
   下次自動續期約 11/25,憑證 12/30 到期,中間沒重啟 Apache 就會再掛一次。
   補強腳本已備好(2026-10-02):`C:\win-acme\Scripts\Setup-ApacheAutoReload.ps1`(管理員跑一次,把兩份 renewal 的
   安裝步驟改成 Script 外掛 GUID `3bb22c70-358d-4251-86bd-11858363d913` + `RestartApache.ps1 {CertCommonName}`,
   並立刻重啟套用)。`RestartApache.ps1` 會先 `httpd -t`、比對 SNI 實際送出的憑證與 PEM 檔到期日,沒換上才改 Restart-Service。
   踩雷:PS 5.1 下 `httpd -t` 的「Syntax OK」走 stderr,`ErrorActionPreference=Stop` 會當例外;非管理員跑
   `httpd -k restart -n Apache2.4` 回傳 0 但什麼都沒做。使用者是否已執行設定腳本:看 `C:\win-acme\Scripts\RestartApache.log`。

非管理員也能跑 `wacs.exe --renew --force --id <id>` 成功簽發(PemFiles 寫到 `C:\Apache\conf\letsencrypt`),
但 Apache 重啟一定要管理員。查網站打不開時:先 `sc query` 服務 → 再 `curl -v` 看 TLS 錯誤碼,別先猜反代。

相關:[[workflowui-public-url]] [[utilhub-deploy-canonical-repo]]
