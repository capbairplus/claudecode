---
name: powershell-npm-ps1-execution-policy
description: "This Windows machine's PowerShell execution policy blocks npm-installed .ps1 CLI shims (e.g. claude.ps1)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 152ee7cb-76d0-416f-a5c6-fdfe99d27ac8
---

Running globally npm-installed CLI tools by their bare name (e.g. `claude ...`) in Windows PowerShell on this machine fails with `PSSecurityException: UnauthorizedAccess` because PowerShell resolves to the `.ps1` shim (e.g. `claude.ps1`) and script execution is disabled.

**Why:** Default/locked-down PowerShell execution policy on this user account blocks `.ps1` scripts, but npm still generates a `.ps1` launcher alongside `.cmd` and the extensionless shim for every global package.

**How to apply:** When a globally-installed Node CLI fails this way in a PowerShell session on this machine, first try calling the `.cmd` shim explicitly (e.g. `claude.cmd mcp add ...` instead of `claude mcp add ...`) — works immediately, no security setting changes. Only mention the permanent fix (`Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`, user-scope only) as something the user runs themselves — don't run it, since changing execution policy is a security-setting change.
