---
name: workflowui-postprocess-cards-0816
description: "2026-08-16 新增的後製/工具類卡片(放大、去背、修臉、反推提示詞、首尾幀影片、影片補幀)與文字輸出卡機制,以及 .161 上做不了的東西"
metadata: 
  node_type: memory
  type: project
  originSessionId: 43c61d1b-8971-4d1f-89e6-6b9ae04e3a27
  modified: 2026-08-16T06:57:53.493Z
---

2026-08-16 一次補了 8 張「後製 / 工具」類卡片(之前的卡都是從無到有生東西,缺的是把成品修好的鏈路)。
Python 版(`G:\claudecode\WorkflowUI`)與 C# 版(`C:\wordpresscb\workflowui-csharp-poc`)都放了。

**7 張已對真 .161 驗證可跑**:`upscale_fast`(ESRGAN 4x,~15s)、`upscale_sd`(UltimateSDUpscale
+ SDXL,~76-112s)、`rembg_product`(WAS `Image Rembg`,透明/白底/綠幕一個 select 搞定,~12s)、
`face_detailer`(FaceDetailer + `bbox/face_yolov8m.pt` + `sam_vit_b`)、`caption_florence`
(Florence2 `Florence-2-large-PromptGen-v2.0`,反推 prompt/tag)、`wan_flf2v`(首尾幀影片,
直接複製 `wan22_i2v` 那份已驗證的 graph、把 `WanImageToVideo` 換成 `WanFirstLastFrameToVideo`
加 end_image,49 幀約 233s,實測首尾幀真的都被吃進去)、`video_enhance`(`RIFE VFI` 補幀 +
逐幀 ESRGAN,24→47 幀、576×896→1152×1792 約 176s)。

**新機制:文字輸出卡**。`caption_florence` 的輸出節點(`ShowText|pysssss`)不產圖也不產影片,
ComfyUI 把結果放在 history 的 `outputs[node]["text"]`(字串陣列)。改了 `_run_job` 沒 media 時
存成 `.txt`(Python `routers/generate.py`、C# `Services/GenerateService.cs`)、gallery 的副檔名
白名單、前端用 `<pre>` fetch 顯示、C# 的 `/api/jobs/{id}/output` 補 `.txt` content-type。
另外踩到:manifest 每個欄位都必須有 `node_id`/`input_key`,這種卡沒有 SaveImage 可以掛檔名前綴,
解法是在 graph 裡放一個**沒接線的 `PrimitiveString` 節點**——ComfyUI 不執行沒被輸出節點依賴的
節點,實測不影響。同一招之後任何「輸出不是檔案」的卡都能用。

**新增的 category**:`upscale` / `postprocess` / `caption` / `video_edit`(Python 的
`manifest_schema.py` 是 Literal 要改,C# 的 Category 是純字串不用改;兩邊前端各自要補圖示與
「影片區」分類集合)。

**踩到的雷:VHS_LoadVideo 對無音軌影片會爆**。2026-08-16 當天 .161 的 ComfyUI 從 0.18.2 被更新到
0.33.1(中途服務斷過一次,不是我們的 job 弄掛的),之後 `VHS_LoadVideo` 遇到沒有音軌的影片直接
失敗(`VHS failed to extract audio ... Output file does not contain any stream`)——ComfyUI 的
輸出快取會走 VHS 的 lazy audio map,**graph 裡沒用到 audio 也一樣爆**,拔連線沒用。Wan 生出來的
片子都是無聲的,剛好打到 `video_enhance` 的主要用途,`faceswap_video` 也一樣中。修法在我們這側:
上傳的影片沒音軌就先用 ffmpeg `anullsrc` 補一條無聲軌(影像 copy 不重壓)再送出——
Python `services/video_inputs.py` + `card_processors.py` 的 `VHS_VIDEO_FIELDS`;
C# `Services/VideoInputService.cs` + `Program.cs`。已實測修好。

**C# 版呼叫 ffmpeg 會 deadlock(已修)**:`LipSyncInputService.RunProcess` 原本先
`StandardOutput.ReadToEnd()` 讀完才讀 stderr,ffmpeg 的 stderr 一塞爆 pipe buffer 就雙方互等——
整個 `/api/generate` 請求掛住、留下一支殺不掉的 orphan ffmpeg(要提權才能 taskkill)。改成兩條
管線用 `ReadToEndAsync()` 同時排空,並加 `-hide_banner -loglevel error`。**新寫任何 C# 呼叫外部
程式的地方都要照這個寫法**。Python 版沒這問題(`subprocess.run(capture_output=True)` 本來就會
同時排空兩條管線)。

**當天稍後補做完成的兩張(下載模型到 .161 後啟用,共 9 張卡全部可用)**:
- **`liveportrait_expr`**:`models\liveportrait\` 原本只有 `landmark_model.pth`,主模型全缺
  (節點自己的 `snapshot_download` 沒真的抓下來;錯誤訊息 `argument of type 'int' is not iterable`
  其實是 `load_torch_file` 讀不到檔案時 comfy/utils.py 的錯誤處理自己爆掉,不是模型壞)。從
  `Kijai/LivePortrait_safetensors` 補了 6 個檔(約 600MB,含 `landmark.onnx`)後可用,40 幀約 18 秒。
  **臉部裁切器只有 InsightFace 那條能走**:MediaPipe 被 protobuf 5.29(mediapipe 0.10.x 要 <5)卡住、
  face_alignment 被 torch 2.6+ 的 `weights_only` 卡住。**.161 的 insightface 其實是好的(1.0.1)**,
  ReActor 載入失敗是別的原因,不要再把兩件事混為一談。
- **`wan_vace`**(影片動作移植):下載 `QuantStack/Wan2.1-VACE-14B-GGUF` 的 Q4_K_M(11.6GB)到
  `models\unet\wan\`,配 `lightx2v_T2V_14B` LoRA 跑 6 步 CFG 1。**選 Q4_K_M 不選官方 fp16(34.7GB)
  是因為 .161 的 GPU 是 RTX 4060 Ti 只有 16GB**。控制訊號用 `AIO_Preprocessor` 一個 select 切換
  骨架/深度/線稿/邊緣/原始畫面。33 幀 480×832 約 216~285 秒。

**.161 上仍然做不了的**(2026-08-16 實測):
- `LayerMask: RemBgUltra` 缺 `RMBG-1.4/model.pth`(所以去背改用 WAS 的 rembg,會自己下載模型)。
- Flux Kontext(沒模型)、ACE-Step 音樂(沒 checkpoint)、Hunyuan3D(沒模型)、Flux.2 Klein
  (unet 有裝但沒有對應的 Mistral3 text encoder)、InstantID(核心節點沒載入)。
- ReActor 仍然沒載入(`faceswap_reactor`/`faceswap_video` 兩張卡實際上是壞的,狀態卻寫 ready)。

**C# 版收尾沒做完**:Claude Code 的終端機不是提權執行,`sc stop/start WorkflowUiCsharpPoc` 與
`taskkill` 都 access denied,所以 **`dotnet build` 因為 exe 被服務鎖住而失敗**。不過那次失敗的
build 已經把 `workflow_templates/` 與 `wwwroot/` 複製到 `bin\Debug\net8.0-windows\`,而
`ManifestLoader` 是每次請求重讀,所以 7 張卡在線上(8900)立刻就能用、也實測過生成成功;只有
`caption_florence` 需要新版 binary(文字輸出),已先把**輸出目錄那份** manifest 的 status 改成
`needs_confirmation` 擋著,等使用者在提權 PowerShell 跑
`sc.exe stop` → `dotnet build` → `sc.exe start` 後,專案目錄那份(status: ready)會覆蓋回去。

相關:[[workflowui-vision]] [[workflowui-public-url]] [[video-card-pattern-and-reactor-gap]]
[[comfy-161-network-access]]
