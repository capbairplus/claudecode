---
name: comfy-161-network-access
description: "這個 sandbox 對 192.168.1.161:8188 的直連可達性會變動——同一 session 內遇過先失敗後又通,每次要用前先實測,別憑之前的結果認定"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 92ab833c-c89b-4938-aca8-e0caaec12ab3
  modified: 2026-07-25T04:50:16.006Z
---

**這件事不穩定,不要當成固定結論記死**:2026-07-25 同一個 session 裡,一開始直接對
`192.168.1.161:8188` 發 HTTP 請求失敗(`All connection attempts failed`),但後來同一個 sandbox
同一個 port 直連又通了(`curl http://192.168.1.161:8188/system_stats` 回 200,WorkflowUI 的
`/api/health` 也回 `ok:true`)。中間沒有明顯操作變因,原因不明(可能是沙盒網路出口本身會變、也可能
跟 .161 那端防火牆/服務狀態有關)。

**SSH 一直是穩定備援**:`ssh -o BatchMode=yes chavi@192.168.1.161 "..."` 全程都通,不受這個影響。

**How to apply**:
- 每次要對 .161 的 ComfyUI 做真的 API 呼叫前,**先實測一次直連**(例如打 `/system_stats`),不要
  沿用「之前測過失敗/成功」的舊結論。
- 直連失敗時退回 SSH 方案:把檔案 `scp` 到 .161(例如 `D:\ComfyUI_windows_portable\` 底下,測完刪
  乾淨),用 `ssh chavi@192.168.1.161 "... python_embeded\python.exe xxx.py"` 在 .161 本機執行,
  腳本裡打 `http://127.0.0.1:8188`。
- 不要用 `schtasks`/背景排程去 .161 上跑東西(會在 chavi 的 interactive session 彈出可見視窗,見
  CLAUDE.md 的 SSH 操作規則),一般 SSH 執行完就結束的腳本沒有這個問題。

**已驗證過的實際成果**(2026-07-25):
- `img2img_qwen` 卡片的 workflow(Qwen Image Edit)對 .161 實測成功,產出身分保留的正臉照片。
- 把 .161 上既有的 UI 格式 workflow(`anyih_validation.json`,litegraph 格式)手動轉成 API 格式,
  對照 `/object_info` 的 `input_order` 逐一核對欄位順序,submit 前用 combo 選項清單先檢查檔名是否
  存在,再送 `/prompt`——這個轉換流程實測成功,產出正確的 Flux+LoRA 文生圖結果,已經拿來做
  `txt2img_flux` 卡片的 `workflow_api.json`。

相關:[[workflowui-vision]]
