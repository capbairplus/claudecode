---
name: taipei-city-map-project
description: 臺北市街道地圖(TaipeiCity P01 PDF 樣張)專案的程式位置、新舊輸出位置、現況版本與使用者訂的標註規則
metadata:
  type: project
---

臺北市街道地圖專案(原由 Codex 做到 v41;2026-11-21 起由 Claude 接手)。

- **程式/文件**:`D:\MyProject\MyPlan\TaipeiCity\`(主程式 `build_pdf_pilot.py`、`poi_icons.py`;總驗收入口 `docs\TaipeiCity_master_acceptance_checklist_2026-11-20.md`;Python 用 `.venv`,它吃系統 site-packages,所以別加 `-I`)
- **舊輸出**:`G:\Codex\output\taipei-city-pdf-pilot\`(v1–v41)
- **新輸出(使用者 2026-11-21 指定)**:**所有輸出一律放 `D:\MyProject\Map\TaipeiCity\`**。`build_pdf_pilot.py`、5 支 `audit_*.py`、兩支 preview 腳本的輸出都已改到這裡(2026-11-21;舊資料經 `LEGACY_DIR` 唯讀)。全市母本/網站版腳本(`build_master.py`、`build_browser_map.py` 等與 `MASTER_DB`)仍指向 `G:\Codex\output\taipei-city-master-map`/`-browser-map`,使用者還沒要求改。
- **授權總表**:`D:\MyProject\Map\TaipeiCity\TaipeiCity_source_license_table_2026-11-21.md`。主要缺口:PDF 頁尾缺 OSM copyright 網址/ODbL 字樣與政府開放資料逐一顯名;`P01_place_index.csv` 附件含 OSM 衍生資料須註明 ODbL;Segoe 字形轉路徑是否違反 MS 字型「不得轉換」待確認。
- **環境**:`requirements.txt` 已補齊並鎖版本(2026-11-21),pip 裝不到的(Noto/Segoe 字型、`D:\Codex\_sources\maps` 快照、G: 母本 sqlite、Edge、Cairo DLL)寫在專案 `SETUP.md`;乾淨 venv 實測可重建出與 v45 內容相同的 PDF。
- **建檔 checklist**:同資料夾 `TaipeiCity_map_build_checklist_2026-11-21.md`;總驗收清單已同步到 v45。
- **現況**:v45(`taipei_P01_icon_name_units_v45_2026-11-21.pdf`),驗收紀錄 `D:\MyProject\Map\TaipeiCity\P01_v45_icon_name_units_2026-11-21.md`。建置一次約 2 分鐘。

**使用者訂的標註規則(2026-11-21)**:
1. 地圖與頁面下方圖例用「左側書籤同款」圖示(Segoe UI Emoji 單色字形,★/☾ 用 Segoe UI Symbol),同色。
2. 標準樣式是「圖示+名稱」(例:🏫西松國小):名稱緊貼在圖示右側、垂直置中;**圖示與文字都不准重疊**。名稱被推到圖示上/下/遠處,他明確說「很不理想」。

**How to apply:** 改排位後一定要跑 `qa_p01_units.py <pdf>`(檢查圖示疊圖示/疊文字、文字疊文字、名稱尾端離下一個圖示太近、圖示右側沒有名稱)和 `qa_p01_pdf.py`。總覽 1:5,000 的位移上限是 6 pt(約 10 m),超過就省略、交給分幅;不要為了全標出來把圖示推到百公尺外(v43 踩過,最遠到 229 m)。
