---
name: vigor2960-admin-tools-suite
description: "Five PHP admin tools on the Solis webserver (192.168.1.33) for managing the Vigor 2960 router — backup, log download, log analysis, firmware check, config restore"
metadata: 
  node_type: memory
  type: project
  originSessionId: 9d78ef7b-8dc1-4e1f-8b53-94271739de82
---

Built a suite of 5 PHP tools on the Solis webserver (192.168.1.33, public at www.solistex.com) to manage the Vigor 2960 router (192.168.1.1), all following the Selenium-automation pattern from [[vigor2960_cli_write_bug]] since CLI writes don't reliably take effect on this router.

All pages live in `C:\wordpresstemp\` on 192.168.1.33 and are protected by the same HTTP Basic Auth as `changetempip.php` (`.htaccess` `<FilesMatch>` covering all of them; `.htpasswd` outside the web root at `C:\wordpresstemp_auth\.htpasswd`).

Pages:
- `backup-vigor.php` + `selenium/backup-config.ps1` — downloads a `.tgz` config backup, lists past backups with download links.
- `download-log-page.php` + `selenium/download-log.ps1` — downloads the router's syslog `.txt`, lists past downloads, links each to analysis.
- `analyze-log.php` — pure PHP (no Selenium), parses a downloaded syslog for PASS-by-source, port-scan signatures (≥5 distinct dest ports from one source), BLOCK leaderboard, and IKE/VPN noise summary.
- `firmware-check.php` — pure PHP, compares installed firmware (via `vigor-query.ps1` CLI query) against DrayTek's official download page; downloads a newer `.bin` if found but never applies it (manual Web UI upload only — flashing firmware is left to a human).
- `restore-config.php` + `selenium/restore-config.ps1` — restores a `.tgz` backup via the real Web UI (系統維護 > 設定備份 > 還原, native `<input type=file name=selectfile>`). Requires an explicit confirmation checkbox in the UI (this overwrites live config and reboots the router). **Not yet live-tested end-to-end** (a real restore causes a brief router reboot/outage, so the actual restore submission was deferred pending user confirmation) — the page and script are deployed and auth-verified (401/200), but only the Web UI structure (file input, tab, submit button XPath) was inspected live, not a full restore run.

Shared PowerShell helper module: `selenium/vigor-common.ps1` (dot-sourced by every *.ps1 above) — `New-VigorDriver`, `Find-VigorElement`, `Connect-VigorWebUI`, `Open-VigorMenu`, `Resolve-Password`.

**How to apply**: if asked to extend or debug any of these tools, read the existing script first — they all share the same headless-Chrome-via-vigor-common.ps1 pattern, Big5→UTF-8 output fix, and Basic Auth gating. Don't reintroduce CLI-based writes for anything that needs to actually take effect on the router.
