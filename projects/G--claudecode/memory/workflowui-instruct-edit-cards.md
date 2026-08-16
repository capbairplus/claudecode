---
name: workflowui-instruct-edit-cards
description: "指令式圖片編輯兩張卡(Flux.2 Klein 9B / Flux.1 Kontext Dev)已完成並對 .161 驗證,含兩者實測差異與 Klein 的 VAE 替換"
metadata: 
  node_type: memory
  type: project
  originSessionId: 6ea7b37a-af12-47e6-b0a7-b662e75955fe
  modified: 2026-08-16T07:41:10.820Z
---

2026-08-16 完成 `instruct_edit` group 的兩張卡,都已對真的 .161 生成驗證過(不是只跑 mock)。

**`flux2_klein_edit`(Flux.2 Klein 9B distilled)**
- .161 上模型/text encoder/VAE 本來就配齊,**一個檔都沒下載**:`flux\flux-2-klein-9b-fp8.safetensors`
  + `qwen_3_8b_fp8mixed.safetensors`(CLIPLoader type=**flux2**)+ `flux2-vae.safetensors`。
  Klein 用 **Qwen3** 當 text encoder,不是 Mistral(Mistral 是 FLUX.2 **Dev** 用的)——這點我一度搞錯。
  4B 版用 `qwen_3_4b.safetensors`,9B 版用 `qwen_3_8b_fp8mixed`,兩者不能混。
- ⚠ 官方 template 指定的 VAE 是 `full_encoder_small_decoder.safetensors`,**.161 上沒有**;
  改用官方文件給 Klein 指定的 `flux2-vae.safetensors`,實測正常。
- 走 `SamplerCustomAdvanced` + `Flux2Scheduler`(steps=**4**,distilled 原廠設定)+ `CFGGuider`(cfg=1);
  正負 conditioning **各接一個 `ReferenceLatent`**(共兩個,都吃同一個 VAEEncode 的 latent)。
- 尺寸靠 `ImageScaleToTotalPixels` → `GetImageSize` → 餵給 `Flux2Scheduler` 和 `EmptyFlux2LatentImage`,
  所以輸出比例跟來源圖走,使用者只調「百萬像素」。

**`flux_kontext_edit`(Flux.1 Kontext Dev)**
- 只缺主模型,已下載 `flux1-dev-kontext_fp8_scaled.safetensors`(11.9 GB,Comfy-Org 的 HF repo)到
  `D:\ComfyUI_windows_portable\ComfyUI\models\diffusion_models\flux\`。**丟進去後不用重啟 ComfyUI**,
  `/object_info` 直接就掃到了。
- text encoder / VAE 沿用其他 Flux 卡已驗證的組合:`flux1\t5xxl_fp8_e4m3fn` + `clip_l` + `ae.safetensors`。
- `ImageStitch → FluxKontextImageScale → VAEEncode → ReferenceLatent → FluxGuidance(2.5) → KSampler(20步, cfg=1, euler/simple)`。
  negative 是 `ConditioningZeroOut` **直接接 KSampler**,沒再過 ReferenceLatent(跟 Klein 不同)。
- 第一版單圖:`ImageStitch` 的 `image2` 是 optional,省略即可單張透傳;要做多圖版再補第二個圖片欄位。

**同一句指令的實測差異**(棚拍白底人像 →「換成陰天日落的海岸懸崖,人物保持原樣」):
- Klein:確實給了海岸懸崖+海,臉部身分保留較好,環境光會跟著改。
- Kontext:背景變成**山景**日落(沒照 coastal cliff 走),臉型有點往西方臉飄。
- 這次兩邊耗時都約 80 秒,但**含首次載入模型**,不能拿來比單步速度(Klein 4 步 vs Kontext 20 步)。

相關:[[workflowui-cards-progress-0731]] [[comfyui-builtin-template-subgraph]]
