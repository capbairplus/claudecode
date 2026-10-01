---
name: comfy-output2-vanishing-files
description: .161 ComfyUI 輸出到 NAS output2 後約 45 秒內就被某個程序搬走,/view 會 404;偶發的「下載成果 404」是這個競態
metadata:
  type: project
---

2026-10-01 實測:.161 ComfyUI 以 `--output-directory \\solisnas\solisftp\comfyui\output2` 執行,
存出來的檔在 `/view` 上**只活約 45 秒**就 404(同一 prefix 的計數器也因此一直是 00001)。
.161 與本機的排程工作裡都找不到搬檔的東西,推測是 NAS 端的程序;ArtGallery 節點沒有搬檔邏輯。

影響:C# `GenerateService` 是完成後立刻 `/view` 下載,所以通常沒事,但偶爾會撞上搬檔週期 →
工作顯示 `Response status code does not indicate success: 404`(faceswap_video 第一次跑就中,重跑成功)。
自己寫測試腳本要「完成當下立刻抓輸出」,不要先抓 input 再抓 output。

還沒查到搬檔程序是誰,也還沒在後端做補救(例如 404 時改從 NAS 路徑讀)。

相關:[[comfyui-161-launch-output2]] [[workflowui-1001-platform-and-cards]]
