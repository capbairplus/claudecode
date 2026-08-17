---
name: comfy-161-shared-machine-gpu
description: .161 的 GPU 會被 ollama 常駐模型和 Blender 等背景程式佔住,量測 ComfyUI 生成速度前一定要先確認 GPU 實際可用量
metadata:
  type: project
---

**.161(RTX 4060 Ti 16GB)的 GPU 是跟別的東西共用的。**2026-08-16 踩到:同一張卡、同一組參數、
同一個 graph,早上每步約 14 秒,晚上變成**每步 350–400 秒(慢 25 倍)**。

排除過的假設(都不是原因,但排除過程本身有參考價值):
- 不是 WorkflowUI 的 graph 有問題 —— 從佇列撈出實際送出的 graph 逐欄核對,跟直送腳本一模一樣。
- 不是 prompt 快取 —— 直送腳本換全新 prompt 也一樣慢。
- 不是 latent 太大 —— 512×320×49(最小配置)也要 11.6 分鐘。
- 不是 VRAM 碎片 —— 重啟 ComfyUI 到乾淨狀態(free 14.9GB)仍然慢。
- 不是 PCIe 降速或降頻 —— `nvidia-smi` 顯示 Gen4 x8(= max)、時脈正常、溫度 58°C、
  throttle reasons 全部 Not Active。
- 不是 `LTXAVTextEncoderLoader.device` 該設 cpu —— 改了沒用(當時誤判)。

**真正原因**:`ollama ps` 顯示 **qwen3:8b 常駐 GPU 佔 6.0GB**,而且 GPU 使用率持續 96%;GPU 程序
清單裡還有 **Blender 5.1**。加上桌面程式,13.8GB 被佔走,LTX 的 13.4GB transformer 根本擠不進去,
每步都要把權重搬進搬出 + 重新 dequant GGUF。

**所以量測速度前的必做檢查**(只看 ComfyUI 的 `/system_stats` 不夠,它不會告訴你是誰在用):
```
nvidia-smi                              # 看 memory.used、GPU-Util 和完整 process 清單
ollama ps                               # 看有沒有模型常駐 GPU、佔多少
```
機器忙的時候測出來的數字沒有意義,不要拿去下效能結論、更不要據此改設定。

**ollama 的 keep_alive 會一直續期**:`ollama ps` 的「4 minutes from now」監看了 9 分半完全沒有倒數,
代表有東西持續在送請求。WorkflowUI 自己的 `llm_expand`(`services/ollama_expand.py`,提示詞擴寫)
就是會打 ollama 的其中一個來源。要釋放得用 `ollama stop <model>`,但那可能中斷別人正在進行的工作,
先確認呼叫來源再動。

**跑完要主動還顯存**:`POST /free {"unload_models": true, "free_memory": true}`。ComfyUI 預設把模型
留在 VRAM 當快取(佇列清空後 free 仍是 0.0GB),對共用機器很不友善。實測釋放後回到 14.8GB。

**反過來也成立**:LTX 這種大 job 會把 GPU 吃到 99%,拖垮機器上其他人的工作。發現機器忙就該
`POST /interrupt` 停掉,不要硬跑完。

相關:[[workflowui-ltx23-card]] [[comfyui-161-upgrade-0816]] [[verify-before-claiming-unreachable]]
