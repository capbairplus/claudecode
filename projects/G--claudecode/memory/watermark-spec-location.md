---
name: watermark-spec-location
description: 去浮水印規範文件固定放 D:\MyProject\MyTraining\watermark\rule\、檔名固定;改版時舊檔改名保留,新版用標準檔名
metadata:
  type: feedback
---

去浮水印的規範只有一份現行版,固定在 `D:\MyProject\MyTraining\watermark\rule\去浮水印體系_v2_規範與演算法.md`。以後更新都寫進這個目錄;改版時先把舊檔改名(加 `_舊版_YYYYMMDD`)留在同目錄,新版永遠用標準檔名。不再寫到 `docs\`。教訓與規則寫進這份規範,不要寫進 CLAUDE.md。

**Why:** 2026-11-04 使用者(TOEIC 入門先修班去浮水印)連續指出漏抓(貼底浮水印、起訖沒外推到完全消失),並質疑規範「寫了好幾天、冗餘又不足」;舊規範是追記式累積(§0…§10),前後互相矛盾,12 條 MUST 只有 4 條有程式強制,使用者要的是單一、現行、可執行的規範。使用者明確說要寫進這份規範,不是 CLAUDE.md。

**How to apply:** 去浮水印工作開工前先讀這份規範的「未實作」清單;回報前對照它的完成定義。使用者說「總檢討」時是討論,聽完再動手;「停下來」之後要先問「要我現在動工嗎?」。
