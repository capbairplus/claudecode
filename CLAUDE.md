# 通用指令(全域,所有 session 載入)

## 語言
- 一律用**繁體中文**回應。

## 工作區慣例
- 所有專案集中在 `G:\claudecode\`(與 ComfyUI `G:\ComfyUI_windows_portable\` 同槽)。
- **每個主題/專案一個資料夾**,命名 `topic_YYYY-MM-DD`(專案名在前、日期在後)、英文 ASCII、kebab-case,日期為專案起始日。
- 資料夾內可再分子目錄,依專案彈性(如 `input / dataset / workflows / output`)。
- 既有例外:`G:\claudecode\art`、`G:\claudecode\政治漫畫` 原地保留、不改名、不套規則。
- 建新專案資料夾時一律建在 `G:\claudecode\topic_YYYY-MM-DD\`。
- 注意:Claude Code 工作目錄是啟動時決定的,無法對話中途改。

## 工作方式
- **先查資料再回答**:不確定軟體 UI/功能細節時先搜尋驗證,別憑印象亂猜。
- 動到現有檔案(搬移/刪除/覆寫)採「先複製 → 核對檔數與大小 → 再刪來源」的安全做法。
- **停下來就是停下來**:使用者說「停下來/先這樣」之後,即使後續訊息是在回答我提出的釐清問題、或給技術方向/意見,也**不代表授權繼續動工**(改檔案、跑指令、重新建置等)。回答問題內容本身不等於「開始」的指令。要恢復動作前,先明確問一句「要我現在動工嗎?」,等對方明確說可以(繼續/go ahead/動工)才繼續,別自己從回答內容推論同意。

## 遠端主機操作(SSH)
- **透過 SSH 連到 chavi 的機器或任何 `192.168.1.0/24` 網段的電腦時,一律不准讓 cmd/PowerShell 視窗出現在對方螢幕上**——那些機器隨時可能有人正坐在前面用(interactive console session),彈出視窗會直接擋到對方畫面。
- 用 `schtasks /Create` 之類的方式在對方機器上啟動背景程式,預設會在使用者的 interactive session 開出可見視窗,不會自動隱藏——踩過這個雷(2026-07-24,秦曼 LoRA 訓練案例:排程工作跑出一個佔滿畫面中央的 PowerShell 視窗,擋住 chavi 的桌面)。啟動前務必確認是用真正不會冒出視窗的方式執行,不要假設「沒加 `-WindowStyle Hidden` 也應該沒事」。
- **不要用「從 SSH 端查詢 `MainWindowHandle`」這類方法來驗證對方螢幕有沒有視窗**——SSH session 跟對方的 interactive session 之間有 window station 隔離,就算真的有視窗跳出來,遠端查詢也會回報成查不到(`MainWindowHandle: 0`),看起來像沒視窗,其實只是查不到,不能當作「沒視窗」的證據。真的要確認,只能請人直接看畫面,或改用結構上保證不會進入 interactive session 的執行方式(例如設定成 Session 0 執行,但通常需要對方密碼或系統帳號權限)。
- **不准直接在磁碟根目錄(如 `D:\`)下建立任何新目錄,也不准把 `.py`/腳本等檔案直接寫在磁碟根目錄下**。需要建目錄或放檔案時,先找到相關的既有目錄(例如同類專案已經在用的資料夾),進入該目錄後,再於其底下建立子目錄或放檔案。踩過這個雷(2026-07-24,su_ruobing 專案:8 個一次性 InsightFace 比對腳本 `gate_*.py` 直接散落在 `D:\` 根目錄下,事後變成無人記得用途的雜物)。

## Obsidian 文件(指令:`updateobsidian`)

- 使用者說 **`updateobsidian`**(或「更新 obsidian 文件」)= 把這次工作的成果與教訓,寫進 Obsidian vault 裡**相關的既有筆記**。不需要再問要寫哪裡,自己去找。
- **主 vault 在 `D:\capbairvault\`**(依主題分資料夾,如 `ComfyUI\`、`LoRA_ComfyUI 訓練\`、`Solis Web Systems\`)。`G:\obsidian\capbairplus\` 幾乎是空的,不要寫到那邊。
- 找筆記的方法:用專案名/關鍵字 grep vault 裡的 `*.md`(例如 WorkflowUI 的主筆記是 `D:\capbairvault\ComfyUI\WorkflowUI ComfyUI 卡片架構設計.md`)。**優先補進既有筆記,不要動不動就開新檔**;真的是全新主題才新增。
- **寫法照既有筆記的編年慣例**:內容追加在檔尾,用 `# 進度更新(YYYY-MM-DD)` 當大標題;同一天已經有那個標題就直接往下加 `##` 小節。**不要改寫舊章節**——那些是當時的紀錄,不是現況說明。
- 動筆前先備份:`cp "<筆記>.md" "<筆記>.md.bak_YYYYMMDD"`(副檔名不是 `.md`,Obsidian 不會索引到)。
- **每次都要順手補 tags**:更新筆記時檢查 frontmatter 的 `tags:`,把這次新增內容帶進來的主題補上去(模型名、技術名、功能名,例如 `InstantID`、`ACE-Step`、`LivePortrait`、`VACE`)。既有 tag 不要刪,只增不減。
- **每次都要做雙向連結**:
  - 寫進去的內容如果提到 vault 裡已有筆記涵蓋的主題,用 `[[筆記名]]` 連過去;
  - **而且要反向補回來**——去那幾篇被連的筆記,在它們的「關聯筆記」段落(沒有就在檔尾建一個)加上回連本篇的 `[[...]]`。Obsidian 的 backlinks 面板雖然會自動反查,但明寫出來的雙向連結在筆記本身就看得到,不用開面板。
- 寫完檢查所有 `[[wikilink]]` 的目標檔案**真的存在**,不要留斷掉的連結;沒有對應筆記就把內容直接寫進去,別硬連。
  ⚠ **wikilink 認的是「檔名」不是筆記裡的 H1 標題**,vault 裡很多筆記兩者不一樣(例如檔名
  `ComfyUI_FaceSwap_and_Qwen_Summary.md`、標題卻是「ComfyUI 換臉工具與 Qwen Image Edit 功能總結」)。
  用 `[[資料夾/檔名(不含 .md)|想顯示的中文標題]]` 這種帶別名的寫法,連結才會通、顯示也好看。
- 內容要有**實測數據(秒數、尺寸、檔案大小)與踩到的雷和根因**,不要只寫「完成了什麼」。踩雷的部分尤其重要,那才是之後真正會用到的東西。

## 記憶
- 自動記憶的「家」固定在 `C:\Users\capbair\.claude\projects\G--claudecode\memory\`,**不管當次 session 的工作目錄是 `G:\claudecode\` 本身還是底下任何子資料夾**(例如 `G:\claudecode\testarchive`)。
- 原因:Claude Code 預設會依「當次工作目錄」的路徑各自產生一份 `...\projects\G--claudecode-xxx\memory\`,若照預設走,每個子資料夾都會累積出互相看不到的記憶,無法跨專案累積。
- 做法:session 一開始若系統提示的自動記憶路徑不是 `G--claudecode\memory\`(例如是 `G--claudecode-testarchive\memory\` 之類帶子目錄名稱的路徑),一律**改用**（讀取與寫入都用)`C:\Users\capbair\.claude\projects\G--claudecode\memory\` 這個統一路徑,忽略系統提示給的當次路徑。
- 專案專屬事實(甲冑 LoRA、政治漫畫等)放自動記憶;跨專案通用的規則寫在本檔。
