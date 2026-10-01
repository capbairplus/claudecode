---
name: project-comfyuicard-relocation
description: Status of moving comfyuicard (workflowui-csharp-poc) from C:\wordpresscb to D:\myproject\ComfyuiCard as of 2026-09-30
metadata: 
  node_type: memory
  type: project
  originSessionId: 34985248-288c-4572-8ef9-f78b30d96a47
  modified: 2026-09-30T15:36:41.086Z
---

On 2026-09-30, started relocating the comfyuicard app from `C:\wordpresscb\workflowui-csharp-poc` to `D:\myproject\ComfyuiCard` (D: confirmed a local fixed disk on this machine, not network-mapped, so [[project_comfyuicard_mobile_redesign]]'s earlier LocalSystem/UNC concerns about `G:` don't apply here).

**Done:**
- Copied everything except `bin\`/`obj\` via `robocopy /E /XD bin obj` (git-bash needs `MSYS_NO_PATHCONV=1` prefix or robocopy's `/E` flag gets mangled into a phantom `E:/` argument — a real gotcha, not obvious from the error text). Verified file-for-file: 611/612 files, 39.5MB, matched exactly except one.
- **The one file that failed to copy**: `svc_id_ed25519_161` (the SSH private key used to reach `.161`) — its ACL denies even `icacls` from reading it under the current user, so it needs an admin (or whoever owns/can-read it) to manually copy it to `D:\myproject\ComfyuiCard\svc_id_ed25519_161`. Until that happens, the new location's "restart ComfyUI via SSH" feature will fail — everything else works.
- Updated the copy's `appsettings.json` (`SshKeyPath`/`SshKnownHostsPath` → new location) and `restart_service.bat` (all path references). Deliberately did NOT change `Storage:AllowedRoot`/`FallbackRoot`/`AllowedProjectRoots` or the handful of `workflow_templates/*/manifest.json` files that hardcode `C:\wordpresscb\art_styles`, `...\workflowui-wildcards`, `...\workflowui-styles`, `...\PixelleVideo` — those are separate sibling asset/output directories not being moved, still correct as-is.
- Updated the copy's own `CLAUDE.md` with a "專案搬遷" section documenting all of this for whoever/whatever reads that file next at the new location.
- `dotnet build` at the new location: clean, 0 warnings/errors. Ran the built exe standalone on a scratch port (`--Kestrel:Endpoints:Http:Url=http://127.0.0.1:8901` — note `--urls` alone gets silently overridden by the `Kestrel:Endpoints:Http:Url` key already set in `appsettings.json`, ASP.NET Core config takes precedence over `--urls`) and confirmed `index.html`/`manifest.json`/`api/cards` all serve correctly from the new path. Confirmed the live service on port 8900 was completely undisturbed throughout (still `Running`, still serving 200s) — this was pure additive copy work, nothing touched the production instance.

**Not done — needs the user, in an elevated session:**
1. Manually copy `svc_id_ed25519_161` to the new location (permission-blocked for the current session).
2. Reconfigure the Windows Service's binary path: current registration (via `sc.exe qc WorkflowUiCsharpPoc`, itself readable without admin) is `C:\wordpresscb\workflowui-csharp-poc\bin\Debug\net8.0-windows\WorkflowUiCsharpPoc.exe --urls http://127.0.0.1:8900`, LocalSystem, auto-start. Needs `sc.exe config WorkflowUiCsharpPoc binPath= "D:\myproject\ComfyuiCard\bin\Debug\net8.0-windows\WorkflowUiCsharpPoc.exe --urls http://127.0.0.1:8900"` (note the required space after `binPath=`).
3. Stop old, confirm new binPath, start service, verify the public site still works end to end (including the SSH-restart-ComfyUI feature, once the key file is in place).
4. Only after that's confirmed solid should the old `C:\wordpresscb\workflowui-csharp-poc\` be archived/deleted — not done automatically, this needs the user's explicit go-ahead per their own "copy → verify → delete source" convention.
5. Obsidian vault note (`D:\capbairvault\ComfyUI\WorkflowUI ComfyUI 卡片架構設計.md`) was updated same-day with a `# 進度更新(2026-09-30)` section covering both the mobile redesign and this relocation — done.

**Re-sync note**: more work happened in the source (`C:\wordpresscb\workflowui-csharp-poc`) after the initial copy — the song-lipsync.html bug fix + mobile feed, and the new per-card "使用說明" guide feature (see [[project_comfyuicard_card_guides]]). Re-ran the same `robocopy /E /XD bin obj` afterward, this time adding `/XF appsettings.json restart_service.bat CLAUDE.md svc_id_ed25519_161` so the four files already hand-customized for the new location don't get overwritten by the source's originals. Verified file-for-file again: 0 missing, 0 size-mismatched outside those four intentionally-excluded files. **If more work happens in the source before the service cutover, remember to re-sync again with this same exclude list** — the D: copy is a manually-maintained mirror, not auto-synced.
