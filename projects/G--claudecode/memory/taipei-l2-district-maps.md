---
name: taipei-l2-district-maps
description: 臺北市 L2 行政區圖(內湖/松山/信義/中正)在 161 上的位置、2026-11-25 使用者拍板的上圖政策與已知雷
metadata:
  type: project
---

位置:`\\192.168.1.161\d\mydoc\codex\map\taipei\L2\`(各區 `<區>\`,共用文件 `L2_handoff.md`、`L2_build_checklist.md`,共用檢查 `L2_regression_check.py`、`visibility_policy.py`)。當前成品(2026-11-25):內湖 v74、松山 v31、信義 v15、中正 v17;新區 builder 一律從內湖 `neihu\build_district_l2_v03.py` 複製,不是從另三區舊複本。建置:`ssh 192.168.1.161 powershell -File ...`;`neihu\build_dbg.ps1`(內湖)、`neihu\pipeline_other.ps1`(三區 QA+待整理);成品再跑 `python L2_regression_check.py <pdf>`。

**使用者 2026-11-25 拍板**:公司行號不放(稅籍地址≠辦公處,圖上標會誤導);餐飲只留連鎖品牌清單或官方登記佐證,其他商店只留連鎖,銀行照放;被排除者不進待整理圖層;地圖下方與索引頁寫免責語句「商家資料為參考…以現場為準」;國小機關內部平面圖只做 OSM 有的操場體育館;國宅棟號沒資料不自編(麥帥國宅從待辦拿掉);P01 只是測試稿不動;其他 8 區 builder 暫不做。

**Why:** 使用者把圖當可信參考,不要把沒有來源或會誤導的東西畫上去。
**How to apply:** 新增上圖類別前先問「現場看得到嗎、來源能核實嗎」;改規則當下就更新 handoff/checklist(使用者抓過我只改程式沒改文件)。

**雷:** `add_pending_layer.py` 不可對同一個 PDF 跑兩次(會產生兩個待整理圖層,已加防重複);PowerShell `$ErrorActionPreference='Stop'` 下用 `try { & script *> log }` 會把測試的 stderr 當錯誤,要每個 build 腳本各開一個 `powershell -File` 子行程;Windows 與 pymupdf 路徑下 `python -I` 會找不到 site-packages。
