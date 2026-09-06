---
name: feedback-comfyui-not-ffmpeg-for-video-fixups
description: 影片補幀與改尺寸要用 ComfyUI 的節點,不要拿 ffmpeg 的 fps/scale 濾鏡代替
metadata:
  type: feedback
---

生成出來的影片要**補幀(改 fps)或改尺寸**時,用 **ComfyUI 現成的節點**(RIFE VFI、
ImageResizeKJv2 之類),**不要用 ffmpeg 的 `fps=` / `scale=` 濾鏡去湊**。

**Why:** ffmpeg 的 `fps=` 是複製幀,16→25fps 有超過一半是重複幀,凡是有明顯運動的鏡頭
(走路、鏡頭移動)都看得出頓挫;RIFE 是光流插值,是專門做這件事的工具,而且在 .161 上
本來就有(`video_enhance` 卡在用)。我當時因為「ffmpeg 免費、RIFE 要幾十秒 GPU」而
建議先用 ffmpeg,使用者直接否決 —— **生成階段已經花了幾百秒,後處理省那幾十秒毫無意義,
品質才是重點**。

**How to apply:** 規劃影片管線時,補幀/縮放這類步驟先去 `/object_info` 或 .161 的
custom_nodes 找對應節點,把它接進 workflow;ffmpeg 留給真正只有它能做的事(concat、
掛音軌、精確裁切幀數)。要比較方案時,不要用「工具便宜」當理由壓過品質。

相關:[[comfy-161-shared-machine-gpu]]、[[video-card-pattern-and-reactor-gap]]
