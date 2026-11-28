---
name: capbairnas-disk1-failing
description: capbairnas (DS216play, 192.168.3.26) 硬碟配置與 2026-11-28 查出的 sda 故障
metadata:
  type: project
---

capbairnas = Synology DS216play,192.168.3.26,RAM 657MB。兩顆 4TB 各自獨立、**無備援**:sda → md2 → vg1000 → `/volume1`(98% 滿);sdb → md3 → vg1001 → `/volume2`(88%)。`8T01` 分享推定是 USB 外接碟。

2026-11-28:整台半當機(ping/埠通,但 DSM/SSH/SMB 不回應,QuickConnect 連不上)。sda(ST4000DM000,SN Z304XSXM,Disk 1 橘燈)自 2026-10-22 起反覆記錄 `Disk error reset fail`,當天重開機後又出現;系統分割區已踢掉 sda1。SMART 仍顯示 PASSED。建議先備份 volume1 再換碟,尚未執行。

**Why:** 無備援,拔掉或壞掉 sda 就失去 volume1。
**How to apply:** 之後處理這台 NAS 前,先問 volume1 備份/換碟了沒。SSH 帳密由使用者自己在終端機輸入,我用 read_terminal 讀結果。
