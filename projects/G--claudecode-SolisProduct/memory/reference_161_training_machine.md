---
name: reference-161-training-machine
description: 192.168.1.161(chavi 的機器)是公司 ComfyUI/kohya LoRA 訓練 GPU 主機，含連線與啟動方式注意事項
metadata: 
  node_type: memory
  type: reference
  originSessionId: 3acdcb18-ad8f-4d42-a2bb-4689ca9a5cc7
  modified: 2026-07-25T18:27:11.842Z
---

`192.168.1.161`(hostname `SOLIS-GW-CHAVI`)是 chavi 的個人機器，同時也是公司拿來跑 ComfyUI 生圖與 kohya_ss LoRA 訓練的 GPU 主機(RTX 4060 Ti 16GB)。

- SSH：`ssh -i ~/.ssh/id_ed25519_161 solisadmin@192.168.1.161`（`chavi` 帳號也能用同一把 key）。
- kohya_ss 裝在 `D:\kohya_ss`（venv 在 `D:\kohya_ss\venv`，訓練腳本在 `D:\kohya_ss\sd-scripts\flux_train_network.py`）。
- Flux 底模四件套路徑：
  - `D:\ComfyUI_windows_portable\ComfyUI\models\diffusion_models\flux\flux1-dev.safetensors`
  - `D:\ComfyUI_windows_portable\ComfyUI\models\clip\clip_l.safetensors`
  - `D:\ComfyUI_windows_portable\ComfyUI\models\clip\flux1\t5xxl_fp16.safetensors`
  - `D:\ComfyUI_windows_portable\ComfyUI\models\vae\ae.safetensors`
- 已驗證成功的完整訓練參數配方見 Obsidian 筆記 [[周以諾 Flux 角色 LoRA 完整訓練流程]]（`LoRA_ComfyUI 訓練/` 資料夾）。

**啟動訓練務必用 SYSTEM 排程 detached，不要用一般 SSH 前景/VBS 方式**。
**Why**：這台機器隨時可能有 chavi 本人在用（曾發現她的 ComfyUI python.exe 行程跑了 2 小時+，佔滿 VRAM）；而且透過一般 SSH session 啟動的背景行程（包含用 VBS `WScript.Shell.Run(...,0,False)` 隱藏視窗的方式）會在 SSH session 的 Job Object 結束時被一併砍掉——實測過，訓練腳本本身沒錯，但透過 SSH 直接跑或 VBS 隱藏跑都在幾秒內無聲失敗，只有改用 `schtasks /ru SYSTEM` 才穩定跑起來。
```
schtasks /create /f /tn <task名> /ru SYSTEM /rl HIGHEST /sc once /st 23:59 /tr "<train.bat 完整路徑>"
schtasks /run /tn <task名>
```
`/st 23:59`只是佔位時間，實際靠 `schtasks /run` 立即觸發。查狀態用 `schtasks /query /tn <task名> /v /fo list`。

**已知踩雷**：kohya 訓練 log 裡混了非 ASCII(中日文)字元，Windows 主控台編碼是 cp950，直接 `accelerate launch` 會在印 log 時 `UnicodeEncodeError: 'cp950' codec can't encode character` 崩潰（發生在 `prepare optimizer, data loader etc.` 之後）。**修法**：訓練 bat 裡在 `venv activate` 之後、`accelerate launch` 之前加：
```
set PYTHONUTF8=1
set PYTHONIOENCODING=utf-8
```
[[workspace-convention-gclaudecode]] 提過的 cp950 雷是同一類問題，這裡是它在 kohya 訓練情境下的具體案例。

**開訓練前務必**：`nvidia-smi` 確認 VRAM 是否已被其他行程(常是 ComfyUI 的 python.exe)佔滿；若要砍掉別人的行程一定要先跟使用者確認（涉及 chavi 的工作，不是自己說了算）。

**train_console.log 裡出現「Traceback」不代表訓練真的崩潰**：開訓練初期常見兩個無害的 Traceback（accelerate 內部 reader thread 的 `UnicodeDecodeError`、xformers 找不到 `triton` 套件的 `ModuleNotFoundError`），兩者都是函式庫內部自己 catch 掉、印出來當警告用，訓練會繼續正常跑。監控腳本判斷「真的失敗」要抓更具體的字串（例如 `CalledProcessError`、`CUDA out of memory`），不要看到 `Traceback` 就判定失敗。

**ComfyUI 用 `cl.vbs`(呼叫 `comfyui-listen.bat`)透過 SSH 直接執行一樣會被 SSH session 收掉**，跟 kohya 訓練同個問題——`cl.vbs` 內部也是 `ws.Run("cmd /c comfyui-listen.bat", 0, False)` 這種寫法。要嘛請人在互動桌面 session 手動點開，要嘛也改用 `schtasks /ru SYSTEM` 啟動（但這樣會跳過 `comfyui-listen.bat` 裡指定的 NAS 輸出/輸入路徑 `\\solisnas\solisftp\...`，因為 SYSTEM/非互動 session 連不到 NAS——如果只是要透過 API 抓生圖結果，可以另外寫一個不含 NAS 參數的簡化 bat，直接用 ComfyUI 預設的本機 `ComfyUI\output`/`input` 資料夾即可，不影響 `/prompt`+`/view` API 抓圖。

**Flux 版 IPAdapter(`x-flux-comfyui` 外掛)已知問題**：`LoadFluxIPAdapter` 的 `clip_vision` 參數要選 **`flux\clip-vit-large-patch14.safetensors`**（768 維），選成 `clip_vision_h.safetensors`(1024 維)會在 `ApplyFluxIPAdapter` 直接矩陣維度不合崩潰。就算 CLIP vision 選對了，`ApplyFluxIPAdapter`／`ApplyAdvancedFluxIPAdapter` 送進 `KSampler` 時目前會噴 `DoubleStreamBlock.forward() got an unexpected keyword argument 'attn_mask'`——這是 `x-flux-comfyui` 外掛版本跟目前 ComfyUI 核心版本不相容（核心的 Flux DoubleStreamBlock forward 簽名跟外掛預期的對不上），截至 2026-07-26 還沒解決，需要更新/重裝 `x-flux-comfyui` 外掛才能用 Flux 版 IPAdapter 局部重繪 logo。這台機器沒有 Flux Redux 的 style model 檔案（`StyleModelLoader` 選單是空的），走 Redux 路線需要先下載模型。
