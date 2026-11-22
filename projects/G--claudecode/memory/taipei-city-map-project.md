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
- **全市三層架構(使用者 2026-11-22 定案)**:①全市 1 張 A0 直式 1:30,000;②各區 1 張 ×12,一律 A0、1:20,000(12 區同比例尺;使用者明知小區大半版面是鄰區仍選 A0,鄰區淡化當背景);③分幅 A0、1:5,000(直或橫)共 38 幅;1:600 細部頁保留與否待定。說明文件 `D:\MyProject\Map\TaipeiCity\TaipeiCity_three_level_plan_2026-11-22.md`,參考圖/CSV `TaipeiCity_three_level_plan_2026-11-22.*`(PDF 16 頁,第 1 頁是第 1、2 層圖框;`_levels.csv` 有 13 個圖框中心經緯度)。
- **第 1 層全市圖**:`build_city_overview.py` → 現行 `taipei_L1_city_v02_2026-11-22.pdf`(v02 起名稱只放圖示右側;v01 驗收紀錄 `taipei_L1_city_v01_2026-11-22.md`)。`configure()` 可切換比例尺/紙張,第 2 層共用。
- **松山區已做(2026-11-22,使用者「做松山區」)**:第 3 層 `build_pdf_pilot.py --sheet 松山區:1 --version v01 --date 2026-11-22` → `taipei_L3_songshan-1_v01_2026-11-22.pdf`(A0 橫式 139 頁、60 秒;只列本區門牌/地點、區外淡化、只出有本區門牌的 1:600 分幅 43 張);第 2 層 `build_district_map.py --district 松山區` → `taipei_L2_songshan_v01_2026-11-22.pdf`(A0 橫式 1:20,000,設施取自第 3 層 `songshan-1_place_index.csv`,所以要先建第 3 層)。驗收紀錄 `taipei_songshan_L2_L3_v01_2026-11-22.md`。build_pdf_pilot 不加 `--sheet` 仍產出 P01 v46,已逐頁比對相同(回歸方法:輸出到 scratchpad,比各頁 content stream SHA-256 與附件)。qa_p01_units/qa_p01_pdf 已改成依頁面尺寸、書籤分幅數、旋轉字框比對,`--as-shown` 照預設圖層。下一步:其他 11 區(尚未指定順序)。
- **文件入口(2026-11-22)**:L1 總結 `D:\MyProject\Map\TaipeiCity\TaipeiCity_L1_summary_2026-11-22.md`(程式、資料、使用者累積規則、踩雷、限制)、L2 交辦 `TaipeiCity_L2_handoff_2026-11-22.md`(以 L1 v03 重做各區圖;12 個 L2 圖框有 6 個超出 L1 周邊資料範圍,要先擴資料)。L1 最新成品 `taipei_L1_city_v03_rev4d_2026-11-22.pdf`(白邊=字級×0.05,使用者在近 2000% 放大看字)。
- **L1 現行版 = `taipei_L1_city_v03_rev4_2026-11-22.pdf`(2026-11-22;rev2/rev3 為中間版;Acrobat 開著的檔無法覆蓋,用 `--stem` 另存)**。rev4 併入臺北市官方名冊(`l1v03_official.py`,地址對座標快取 `l1v03_work\address_lookup.pkl`;傳統市場 data.gov.tw 121593);圖例每類別一圖層+左側書籤、手扶梯/電梯圖例、高鐵站、調車場灰塊、DTM 平滑暈渲。agy 兩次交辦都卡權限核准,不要再用。未做:新北官方名冊、7-11 官方名單只有 P01 六區。下面是 v03 初版紀錄:現行 `taipei_L1_city_v03_2026-11-22.pdf`(3 頁、16.5 MB、30 秒),程式 `build_city_l1_v03.py`+`l1v03_build_surroundings.py`(周邊圖資庫 `l1v03_work\taipei_surroundings.sqlite`,OSM 不裁市界)+`l1v03_build_dem.py`(內政部 20 m DTM 在 `D:\Codex\_sources\maps\moi-dem-2026-11-22\`),檢查 `l1v03_qa_units.py`/`l1v03_qa_index.py`,驗收紀錄 `taipei_L1_city_v03_2026-11-22.md`(含未完成:臺北官方名冊未併入、新北官方名冊未取得、商圈/企業總部/步道/纜車/里界/人口等沒做、郵遞區號未對官方表、Acrobat 與 A0 列印未測)。agy 當初停在權限核准沒動工,使用者改要 Claude 自己做。下面是當初交辦 agy 的紀錄:規格 `D:\MyProject\Map\TaipeiCity\L1_v03_agy_handoff_2026-11-22.md`(補周邊新北、巷弄與巷弄名、捷運出口號、臺鐵明線黑淡30%/地下淡70%、高鐵全線淡色、C/B/D/E/F 類、便利超商 1/3 尺寸、商圈、角落小圖、第 2 頁索引、DEM 暈渲;新程式 `build_city_l1_v03.py`,禁改既有 build/qa 程式與母本)。agy 在終端機分頁以 `cmd /c D:\MyProject\Map\TaipeiCity\l1v03_work\run_agy_l1v03.cmd` 互動模式跑(Claude Opus 5.5 High、--mode auto,指令仍要使用者在分頁核准;.ps1 被執行原則擋、背景 --dangerously-skip-permissions 被 auto mode 擋)。進度 `l1v03_progress.md`;禁改檔雜湊基準 `l1v03_work\baseline_hashes_claude_2026-11-22.txt`。驗收:比雜湊、跑 qa_p01_units(全圖層與 --as-shown)、看預覽、核對規格每一項與驗收紀錄。
- **第 1 層踩雷(2026-11-22)**:區界幾何碎成上百段→虛線改「寬帶+細實線」;12 區聯集有細縫→市界粗線畫進市區(先 buffer(1)/buffer(-1) 再只留外環);區界要畫在捷運下面(文湖線沿復興路區界);索引圖層要 clip。
- **第 3 層:依行政區分冊(2026-11-22)**:理由:地址本身帶區名、官方名冊多按區發布、P01 命名問題自然消失。規劃程式 `D:\MyProject\MyPlan\TaipeiCity\plan_district_sheets.py`(舊輸出 `TaipeiCity_district_plan_2026-11-22.*` 只有第 3 層,保留)。規則:區界外盡量畫 300 m、至少 50 m(保證 50 m 時全市 300 m 外擴帶仍畫到 98%;保證 100 m 要 40 幅、300 m 要 43 幅);冊內相鄰圖幅重疊,責任範圍=圖框÷1.2;直/橫式與格網偏移取幅數最少;1:600 分幅只出有本區門牌的格。結果 38 幅:松山1、信義2、大安2、中山2、中正1、大同1、萬華1、文山4、南港3、內湖5、士林8、北投8;5 幅山區為主(門牌<100),估全套約 2,763 頁。**橫式版面建圖程式還沒有**;幅號、外擴寬度、山區比例尺、P01 如何併入仍待定。舊的格網草案 `TaipeiCity_sheet_plan_2026-11-21.*`(plan_city_sheets.py)已被取代,檔案保留。
- **建檔 checklist**:同資料夾 `TaipeiCity_map_build_checklist_2026-11-21.md`;總驗收清單已同步到 v46。
- **現況**:v46(`taipei_P01_official_layers_v46_2026-11-21.pdf`,2026-11-22 完成),驗收紀錄 `D:\MyProject\Map\TaipeiCity\P01_v46_official_layers_2026-11-21.md`。建置一次約 2–3 分鐘。v46 = 使用者要求「有缺漏的都補、沒類別的加類別」:體育局運動場地(河濱籃球場)、國發會機關通訊錄的中央機關(臺北市榮民服務處等,圖上用常用名、CSV 留全名)、健保署醫院診所藥局、財金公司銀行分行、公運處公車站位、觀光署旅宿景點、公園處公園、北市圖;新增 6 類:托嬰與親子館、長照巷弄站、AED、避難收容處所、垃圾車停靠點、河濱出入口。程式在 `official_layers_v46.py`;快照清單 `D:\Codex\_sources\maps\taipei-open-data-2026-11-21\v46_sources_manifest_2026-11-21.json`。官方疏散門資料集(data.gov.tw 121236/117874)已下架,改用「自行車河濱出入口」(143893)。餐廳、具名大樓、其他地點沒有官方名冊可對照。
- **踩雷(2026-11-21)**:另一個 session(fork 交接的「P01 v46」)用同檔名 `*.bak_20261121_v46` 做備份,蓋掉了我改動前的備份。已把 v45 原版還原為 `pilot_sources.py.bak_20261121_v45orig`、`build_pdf_pilot.py.bak_20261121_v45orig`,重建 PDF 與 v45 逐頁相同。**多個 session 動同一專案時,備份檔名要能區分 session,改檔前再核一次備份雜湊。**

**使用者訂的標註規則(2026-11-21)**:
1. 地圖與頁面下方圖例用「左側書籤同款」圖示(Segoe UI Emoji 單色字形,★/☾ 用 Segoe UI Symbol),同色。
2. 標準樣式是「圖示+名稱」(例:🏫西松國小):名稱緊貼在圖示右側、垂直置中;**圖示與文字都不准重疊**。名稱被推到圖示上/下/遠處,他明確說「很不理想」。

**How to apply:** 改排位後一定要跑 `qa_p01_units.py <pdf>`(檢查圖示疊圖示/疊文字、文字疊文字、名稱尾端離下一個圖示太近、圖示右側沒有名稱)和 `qa_p01_pdf.py`。總覽 1:5,000 的位移上限是 6 pt(約 10 m),超過就省略、交給分幅;不要為了全標出來把圖示推到百公尺外(v43 踩過,最遠到 229 m)。
