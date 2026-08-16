---
name: workflowui-pose-controlnet-card
description: "pose_controlnet_flux 卡片(角色 LoRA + OpenPose ControlNet 批次姿勢生成)技術細節、.161 上可用的 ControlNet 模型清單、以及 controlnet 強度的 ghosting 陷阱"
metadata:
  type: project
  originSessionId: current
  modified: 2026-08-11T08:34:42.206Z
---

**2026-08-11 新增 `pose_controlnet_flux` 卡片**(幫角色 LoRA 資料集補姿勢多樣性):流程是
角色 LoRA(鎖臉)+ OpenPose ControlNet(鎖姿勢)+ 內建 15 款姿勢骨架庫,一次批次生一整套姿勢圖。
已對真實 .161 送過生成驗證,`status: ready`。

**.161 上已裝的 ControlNet 相關資源**(2026-08-11 用 `/object_info` 探過,未來要加其他
ControlNet 卡不用再猜):
- `ControlNetLoader` 可選:`flux\Flux.1-dev-ControlNet-Union_Pro-2.0.safetensors`、
  `flux\Flux.1-dev-Controlnet-Jasperai-{Depth,Surface-Normals,Upscaler}.safetensors`、
  `flux\flux-{canny,depth,hed}-controlnet-v3.safetensors`、`flux\flux_dev_openpose_controlnet.safetensors`,
  還有一些 sd 開頭的(SDXL/SD1.5)沒細看。
- `ControlNetApplyAdvanced` 存在(positive/negative CONDITIONING + control_net + image + strength +
  start_percent/end_percent,vae 是 optional)。
- `DWPreprocessor`(照片→OpenPose 骨架,body/hand/face 各自可開關)、`AIO_Preprocessor`(整合一堆
  preprocessor,含 CannyEdge/DepthAnything/DensePose 等)都在。

**姿勢庫是自己畫的骨架圖,不是真人照片**:`backend/workflow_templates/pose_controlnet_flux/pose_presets/`
底下 15 張 PNG,用標準 OpenPose COCO-18 keypoint 視覺化規範(18 個關節點顏色、17 條肢體線段的
配色與連接規則)手刻座標畫出來的 stick figure,直接餵給 `ControlNetApplyAdvanced`,**不經過
`DWPreprocessor`**(那個節點是「照片→骨架」用的,對著已經是骨架的圖再跑會偵測不到人)。好處是完全
沒有肖像/版權問題。畫骨架的一次性 generator script 沒有留在 repo 裡(只是產出用的工具,產物 PNG
才是要留的東西),需要再調整某個姿勢或加新姿勢時要重寫。

**⚠ 實測踩到的坑(2026-08-11,含使用者實際在 UI 上跑出來才發現的問題)**:
1. **不寫服裝會生出裸體**:預設 prompt 只寫了場景/光線沒寫服裝,骨架圖本身也沒有衣著資訊,結果
   Flux + LoRA 直接生出裸體(不是刻意要的)。之後任何用 OpenPose/骨架類 ControlNet 的卡片,prompt
   預設值都必須明確寫服裝描述(如 `wearing casual everyday clothing, fully clothed`),不能只寫
   場景光線就假設模型會自己穿衣服。
2. **單靠骨架 ControlNet 幾乎沒用,踩到專案已知的坑 [[multiangle-node-plus-text-lesson]]**:一開始
   以為 strength 0.5 對「一般姿勢」夠用,結果使用者在真的 UI 上跑「坐地盤腿」「雙手合十」都直接被
   無視、打回普通站姿——後來發現不只大動作,連「雙手合十」這種小動作在 0.5 都沒效果,0.5 基本上等於
   沒有姿勢控制。改成「骨架 ControlNet + 每個姿勢自帶一句文字描述(append 到 prompt 後面)」雙管齊下
   之後才明顯改善,這才是這類姿勢/角度控制卡的正確做法,不能只餵節點不寫文字。
3. **strength 沒有穩定甜蜜點,而且有明顯的 seed 敏感度**:實測 strength 0.9 會把四肢拉得像骨架一樣
   細長崩壞;0.6~0.7 搭配文字大多數狀況正常,但同一個姿勢+文字組合換一個 seed 就可能失敗(打回站姿)
   或肢體扭曲變形(尤其坐姿類),親眼見過同樣是「坐地盤腿」+ strength 0.6 + 文字,某個 seed 完美、
   換一個 seed 直接變成手部扭曲的恐怖畫面。**這不是能靠調參數徹底解決的,是這顆 `flux_dev_openpose_controlnet`
   模型本身對大幅度姿勢的穩定性有限**。目前卡片預設 strength 0.6,help_text 已經寫清楚要「每個姿勢多出
   幾張不同 seed,再挑掉崩壞的」,跟角色 LoRA 資料集擴增本來就該做的把關流程一致,不能預期整批直接全部
   能用。

**通用後端擴充(不只服務這張卡)**:為了讓 repeat 批次表格的某一欄可以「挑一個內建素材檔」而不是打字
輸入文字/數字,幫 `RepeatRowField` 加了 `asset_dir` 欄位 + 新檔案 `backend/app/services/repeat_assets.py`
(`resolve_repeat_assets_for_generate`/`_for_export`,在 build_jobs 之前把 row 裡的 id 換成真的上傳檔名)。
之後如果要做其他「批次挑內建素材」類卡片(例如姿勢庫之外的 canny/depth 範例圖庫),可以直接照抄這個
機制,不用重新設計。

**已移植到 C# 主力版**:2026-08-11 這張卡跟 `asset_dir` 機制也移植到了
`C:\wordpresscb\workflowui-csharp-poc\`(對外公開網址背後真正在跑的版本,見
[[workflowui-public-url]]),已用真的 `/api/generate` 送出並輪詢到 `status:done` 驗證過,圖片
檢查正常。之後任何 Python 版新卡片都要記得比照移植過去,C# 版不會自動跟著更新。

相關:[[workflowui-vision]] [[multiangle-node-plus-text-lesson]] [[workflowui-public-url]]
