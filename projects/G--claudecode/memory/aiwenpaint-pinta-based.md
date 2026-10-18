---
name: aiwenpaint-pinta-based
description: AiwenPaint 現在是以 Pinta 3.2 為基礎的專案(d:\myproject\AiwenPaint),舊 WPF 版已備份到 AiwenPaintLite;功能清單、打包方式、已知環境坑
metadata:
  type: project
---

使用者要做自己的繪圖/修圖軟體(嫌 paint.net / Pinta 功能不足),決定「用 Pinta 做原型,再補不足之處」。

**位置(2026-10-18 整理後)**:`d:\myproject\AiwenPaint` 是 Pinta 3.2 原始碼的衍生專案(MIT,授權檔保留;上游 README 存成 `readme.pinta-upstream.md`)。`d:\myproject\AiwenPaintLite` 是最早自己寫的 WPF 簡易版(已用雜湊核對與原 AiwenPaint 完全一致才取代)。舊名 PintaProto 已不存在。

**已做**:彩色工具圖示、語言只留英文/繁中(預設繁中,zh_TW.po 全翻)、標題列選單按鈕移到左側、AI 去背(特效→照片→移除背景,silueta.onnx 42.1MB,models/ 不進 git)、仿製印章加硬度/不透明度、魔術橡皮擦、反銳利化遮色、色彩平衡、描邊選取範圍、加亮加深/塗抹/模糊銳利化筆刷、投影、透視/斜切。連續曲線 Pinta 本來就有(線條/曲線工具,點線加控制點)。

**打包**:`package.ps1` → `dist\AiwenPaint\bin\AiwenPaint.exe`(自包含約 289MB,整個資料夾要一起搬;圖示/翻譯必須在 `share\` 下,Windows 安裝版配置是 bin+share+lib)。

**Why / 坑**:
- 使用者電腦的使用者層級 `DOTNET_ROOT` 指向只有 .NET 8 的 per-user 資料夾,所以依賴系統 .NET 10 的 `build\bin\Pinta.exe` 雙擊會失敗,要給自包含版。
- 建置/執行需要 `C:\msys64\clang64\bin` 與 `C:\msys64\usr\bin`(msgfmt)在 PATH;SDK 在 `C:\Program Files\dotnet`(10.0.402)。
- 我沒辦法在 Pinta 介面裡自己點測(computer-use 只能授權已安裝的 Start 選單 App);單元測試 + 只擷取該視窗(PrintWindow)是能做的驗證。擷取整個螢幕會拍到別的 App 的私人內容,別這樣做。
- Bash 工具的 `find /` 會卡住並讓資料夾被鎖,改名失敗;不要寫這種指令。

**How to apply**:使用者問「最新程式在哪」→ `d:\myproject\AiwenPaint`;給他 exe 時給 `dist\AiwenPaint\bin\AiwenPaint.exe`。待辦:視窗標題/關於還寫 Pinta(尚未改名 AiwenPaint)、批次處理、漸層對應、圖層遮色片等。
