---
name: windows-session-isolation-interactive-cli
description: "DO THIS FIRST for any Vigor 2960 SSH/interactive-CLI task on this machine — skip straight to the hidden scheduled-task method, do not attempt plink/SSH directly via Bash/PowerShell tool first."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9d78ef7b-8dc1-4e1f-8b53-94271739de82
---

**Read this before running any interactive two-stage-login CLI tool (plink to Vigor 2960, or anything similar) via the Bash/PowerShell tool on this machine.** It will fail every time, no exceptions found across ~10 attempts with different scripts/flags/encodings. Do not spend time re-diagnosing it — go straight to the workaround below.

**Why:** The Bash/PowerShell tool executes in a session isolated from the visible interactive desktop (likely Session 0/service context vs. the user's Session 1). Plain TCP/one-shot commands work fine; anything needing live interactive terminal negotiation (username prompt → password prompt → shell prompt) does not, regardless of how carefully it's scripted. Confirmed root cause, not a guess — see `windows_session_isolation_interactive_cli` background and [[vigor2960-cli-write-bug]] for the full incident writeup.

**How to apply — copy-paste this pattern directly, do not re-derive it:**

A ready-to-use hidden-execution wrapper already exists at `C:\Temp\vigor\run_hidden.vbs`:
```vbscript
Set objShell = CreateObject("WScript.Shell")
objShell.Run "cmd /c """ & WScript.Arguments(0) & """", 0, True
```
(If it's missing, recreate it verbatim at that exact path — `C:\Temp\vigor\` is a short, schtasks-safe path already in this session's working directories.)

To run any command that needs a real interactive desktop session (e.g. `vigor_cmd.ps1`, or any plink-based script):

1. Write a one-shot `.bat` to `C:\Temp\vigor\<name>.bat` that sets any needed env vars, runs the command, and redirects output to `C:\Temp\vigor\<name>_result.txt` (append `echo DONE >>` at the end so you can detect completion).
2. Run via Bash/PowerShell tool (this part IS fine to run directly — only the plink/interactive part needs the workaround):
   ```powershell
   $user = $env:USERNAME
   $tr = 'wscript.exe "C:\Temp\vigor\run_hidden.vbs" "C:\Temp\vigor\<name>.bat"'
   schtasks /create /tn "VigorTask" /tr $tr /sc once /st 00:00 /ru "$user" /it /f
   schtasks /run /tn "VigorTask"
   ```
3. Wait ~20-40s (poll `Get-Item <result file>` for LastWriteTime, or `schtasks /query /tn "VigorTask" /v /fo list` for Last Result = 0), then read the result file.
4. Optionally `schtasks /delete /tn "VigorTask" /f` to clean up.

Keep `/tr` paths short — schtasks has a 261-character limit on that argument, which is why `C:\Temp\vigor\` (not a deep scratchpad path) is used.

This is the same mechanism as double-clicking a `.bat` via File Explorer (also confirmed to work), but fully hidden — no screen takeover, no visible window flash.

**Scope:** applies to *any* task on this machine needing live interactive terminal exchange (SSH two-stage logins, telnet, etc.), not just Vigor. Plain one-shot commands, HTTP requests, `Test-NetConnection`, file I/O, etc. all work fine directly through Bash/PowerShell — no workaround needed for those.

**New symptom confirmed 2026-07-19 ([[project_ytdlp_toolbox_app]]):** the same isolation also blocks GUI automation. A WPF/desktop app launched via `Start-Process`/`&` from the Bash/PowerShell tool runs, and `Get-Process` sees it — but the `computer-use` MCP tool's `request_access` reports it as "doesn't match any installed or running application" and can't screenshot/click it, because computer-use operates against the visible interactive desktop session while the shell-launched process lives in the isolated tool session. There is no known hidden-task-style workaround for this one (unlike the SSH case) — the practical fix is to tell the user to launch the app themselves (double-click the exe) so it starts in their interactive session, then computer-use can reach it; don't burn time retrying `request_access` with name variants when this happens. Static/CLI-level testing of the underlying logic remains fully doable from the shell tool regardless.

See also [[vigor2960-cli-write-bug]] for a separate, unrelated Vigor 2960 issue (CLI writes not propagating to enforcement) that this same hidden-task method is also used to work around when querying router state for diagnosis.
