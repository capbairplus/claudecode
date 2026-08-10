---
name: workflowui-deploy-192-168-1-35
description: "WorkflowUI 已部署到 192.168.1.35(Debian),以 systemd service 常駐,連到同一個 161 ComfyUI"
metadata: 
  node_type: memory
  type: project
  originSessionId: c1e262da-31b3-48db-9de7-9c5d5f0aac53
  modified: 2026-08-09T17:53:26.111Z
---

2026-08-10 把 `G:\claudecode\WorkflowUI` 的原始碼(排除 `.venv`/`__pycache__`/`backend/output`/`backend/tmp`)複製到 192.168.1.35,設成 systemd service 常駐執行,對外提供 `http://192.168.1.35:8899`。

## 環境細節
- 192.168.1.35 是 **Debian Linux**(hostname `debian`),不是 Windows,帳號 `capbair`,SSH 金鑰(本機 `~/.ssh/id_ed25519`)已可登入,但 **sudo 需要密碼**——這台機器沒有 NOPASSWD,凡是要 `sudo apt install`/寫 `/etc/systemd/system/`/`systemctl enable` 這類操作,都得請使用者自己在該機器上手動下指令,Claude 不能代為輸入密碼。
- 這台機器**不是乾淨的部署機**:2026-08-08 才裝過 WordPress + Apache + MySQL(佔用 port 80),同時也在跑;WorkflowUI 用 port 8899 不衝突。`.bash_history` 裡曾留有明文 MySQL root 密碼,建議使用者自行清除/輪替。
- 部署路徑:`~/WorkflowUI`(即 `/home/capbair/WorkflowUI`),venv 在 `backend/.venv`(Linux 用 `.venv/bin/python`,不是 Windows 的 `.venv/Scripts/`)。
- `backend/.env` 內容:`COMFY_HOST=192.168.1.161`、`COMFY_PORT=8188`、`ALLOWED_PROJECT_ROOTS=/home/capbair/WorkflowUI`(這個白名單路徑必須是「跑後端那台機器」上真實存在的路徑,不能照搬 Windows 的 `G:\claudecode` ——`resolve_within_allowed` 會直接擋掉所有請求,見 `backend/app/services/project_paths.py`)。
- systemd unit 檔在 `~/WorkflowUI/workflowui.service`,已 `cp` 到 `/etc/systemd/system/` 並 `enable --now`,service 名稱 `workflowui`。

## 重要澄清:誤解過一次「192.168.3.31:8899」
使用者最初說要複製 `192.168.3.31:8899`,聽起來像遠端 ComfyUI 主機,但查證後發現 **192.168.3.31 其實是這台 Claude Code 執行環境自己的區網 IP**,8899 是本機跑的 WorkflowUI 後端(uvicorn),不是 ComfyUI(ComfyUI 本尊仍在 192.168.1.161)。下次看到「複製 3.31:8899」之類的描述,先確認是不是指本機的 WorkflowUI 服務,而不是急著假設是要 SSH 到某個遠端 ComfyUI 主機。

## Why
使用者要在多一台機器上也能用 WorkflowUI 操作 ComfyUI(161),不需要複製 ComfyUI 本體或模型,因為 WorkflowUI 只是呼叫 161 的 API。

## How to apply
- 之後要更新 1.35 上的程式碼:重新打包（同樣排除 `.venv`/`__pycache__`/`output`/`tmp`)→ `scp` 覆蓋 `~/WorkflowUI` → 若 `requirements.txt` 有變再重新 `pip install` → `sudo systemctl restart workflowui`(這步仍需使用者手動 sudo)。
- 檢查服務狀態:`ssh 192.168.1.35 "systemctl is-active workflowui"` 不需要 sudo。
- 相關:[[workflowui-vision]]、[[comfy-161-network-access]]
