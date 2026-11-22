# run_local.ps1 - run a handoff SPEC with a local CLI agent (codex / grok / agy), no visible extra window.
# Keep this file ASCII-only (Windows PowerShell 5.1 reads BOM-less files as ANSI).
#
# Usage:
#   powershell -NoProfile -File run_local.ps1 -Agent codex -Spec D:\path\SPEC_x.md [-Cwd dir] [-Model m] [-AddDir d1,d2] [-Full] [-TimeoutMin 120]
#
# Output: <spec folder>\_delegate\<jobid>\  (PROMPT.md, run.log, last_message.txt, REPORT.md written by the agent)
param(
    [Parameter(Mandatory = $true)][ValidateSet('codex', 'grok', 'agy')][string]$Agent,
    [Parameter(Mandatory = $true)][string]$Spec,
    [string]$Cwd,
    [string]$Model,
    [string[]]$AddDir = @(),
    [switch]$Full,          # codex: bypass sandbox. Others always auto-approve.
    [int]$TimeoutMin = 120
)
$ErrorActionPreference = 'Stop'
$Spec = (Resolve-Path -LiteralPath $Spec).Path
$specDir = Split-Path $Spec -Parent
if (-not $Cwd) { $Cwd = $specDir }
$Cwd = (Resolve-Path -LiteralPath $Cwd).Path
if ($Cwd -match '^[A-Za-z]:\\?$') { throw "Refusing to use a disk root as working directory: $Cwd" }

$rules = Join-Path $env:USERPROFILE '.claude\skills\delegate\rules_zh.md'
if (-not (Test-Path $rules)) { throw "rules file missing: $rules" }

$jobId = '{0}_{1}' -f (Get-Date -Format 'yyyyMMdd_HHmmss'), $Agent
$jobDir = Join-Path $specDir "_delegate\$jobId"
New-Item -ItemType Directory -Force -Path $jobDir | Out-Null
$report = Join-Path $jobDir 'REPORT.md'
$log = Join-Path $jobDir 'run.log'
$err = Join-Path $jobDir 'run.err.log'
$last = Join-Path $jobDir 'last_message.txt'

$prompt = @"
You are a delegated AI agent (id: $Agent). You cannot see the original conversation.
1. Read this rules file first and obey it: $rules
2. Then read the handoff spec and do exactly what it says: $Spec
3. Write your final report to: $report
   The first 10 lines of the report MUST follow the summary format in the rules file (status DONE/PARTIAL/BLOCKED, ...).
4. Your agent id for backup file names is: $Agent
Write the report in Traditional Chinese. If you cannot finish, still write the report with status BLOCKED.
"@
$promptFile = Join-Path $jobDir 'PROMPT.md'
[IO.File]::WriteAllText($promptFile, $prompt, (New-Object Text.UTF8Encoding($false)))
$short = "Read $promptFile and follow it exactly."

function Q([string]$s) { '"' + $s + '"' }

switch ($Agent) {
    'codex' {
        $exe = (Get-Command codex.cmd -ErrorAction Stop).Source
        $a = @('exec', '-C', (Q $Cwd), '--skip-git-repo-check', '-o', (Q $last))
        if ($Full) { $a += '--dangerously-bypass-approvals-and-sandbox' } else { $a += @('-s', 'workspace-write') }
        foreach ($d in $AddDir + @($specDir)) { $a += @('--add-dir', (Q $d)) }
        if ($Model) { $a += @('-m', $Model) }
        $a += (Q $short)
    }
    'grok' {
        $exe = (Get-Command grok.exe -ErrorAction Stop).Source
        $a = @('--cwd', (Q $Cwd), '--always-approve', '--output-format', 'plain')
        # grok -p cannot take extra dirs ("a session works only in its cwd"): -Cwd must be a common parent of everything it touches
        if ($AddDir.Count -gt 0) { Write-Host 'WARN: grok ignores -AddDir; make -Cwd a common parent folder' }
        if ($Model) { $a += @('-m', $Model) }
        $a += @('-p', (Q $short))
    }
    'agy' {
        $exe = (Get-Command agy.exe -ErrorAction Stop).Source
        $a = @('--dangerously-skip-permissions', '--print-timeout', ('{0}m' -f $TimeoutMin))
        foreach ($d in $AddDir + @($specDir)) { $a += @('--add-dir', (Q $d)) }
        if (-not $Model) { $Model = 'gemini-4-neon-high' }
        $a += @('--model', $Model, '-p', (Q $short))
    }
}

Write-Host "job      : $jobId"
Write-Host "agent    : $Agent ($exe)"
Write-Host "cwd      : $Cwd"
Write-Host "jobdir   : $jobDir"
$started = Get-Date
Push-Location $Cwd
try {
    $p = Start-Process -FilePath $exe -ArgumentList ($a -join ' ') -WorkingDirectory $Cwd -NoNewWindow -PassThru `
        -RedirectStandardOutput $log -RedirectStandardError $err
    $null = $p.Handle   # keeps the handle so ExitCode is readable after exit
    if (-not $p.WaitForExit($TimeoutMin * 60 * 1000)) {
        Write-Host "TIMEOUT after $TimeoutMin min - killing process tree"
        & taskkill /PID $p.Id /T /F | Out-Null
        $exit = 'timeout'
    } else { $exit = $p.ExitCode }
} finally { Pop-Location }
$secs = [int]((Get-Date) - $started).TotalSeconds
Write-Host "exit     : $exit  ($secs s)"
if (Test-Path $report) {
    Write-Host "REPORT   : $report"
    Write-Host '---- first 10 lines ----'
    Get-Content -LiteralPath $report -TotalCount 10 -Encoding UTF8
} else {
    Write-Host "REPORT   : (agent did not write one) see $log / $err"
}
