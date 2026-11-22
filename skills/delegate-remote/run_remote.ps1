# run_remote.ps1 - run a handoff SPEC with codex on a remote Windows PC over SSH (161 / 005 ...).
# ASCII-only on purpose. All Chinese content travels inside files (scp is byte-safe); the ssh command line stays ASCII.
# Never uses schtasks / Start-Process on the remote side: codex runs inside the ssh session, so no window can appear
# on the remote screen (the PCs may have someone sitting in front of them).
#
# Usage:
#   powershell -NoProfile -File run_remote.ps1 -HostAlias 161 -Spec D:\path\SPEC_x.md [-Upload f1,f2] [-Model m] [-TimeoutMin 120]
#
# The remote agent works only in  %USERPROFILE%\delegate_jobs\<jobid>\  (inputs uploaded there, deliverables in out\).
# Pulled back to: <spec folder>\_delegate\<jobid>\  (REPORT.md, out\, run.log, last_message.txt)
param(
    [Parameter(Mandatory = $true)][string]$HostAlias,
    [Parameter(Mandatory = $true)][string]$Spec,
    [string[]]$Upload = @(),
    [string]$Model,
    [switch]$Full,
    [int]$TimeoutMin = 120
)
$ErrorActionPreference = 'Stop'
$Spec = (Resolve-Path -LiteralPath $Spec).Path
$specDir = Split-Path $Spec -Parent
$rules = Join-Path $env:USERPROFILE '.claude\skills\delegate\rules_zh.md'
$sshOpt = @('-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-o', 'ServerAliveInterval=30')

$remoteHome = (& ssh @sshOpt $HostAlias 'echo %USERPROFILE%').Trim()
if (-not $remoteHome -or $remoteHome -notmatch '^[A-Za-z]:\\') { throw "cannot read remote profile from ssh $HostAlias : '$remoteHome'" }
$jobId = '{0}_ssh{1}' -f (Get-Date -Format 'yyyyMMdd_HHmmss'), $HostAlias
$rdirWin = "$remoteHome\delegate_jobs\$jobId"
$rdirUrl = $rdirWin -replace '\\', '/'
$localJob = Join-Path $specDir "_delegate\$jobId"
New-Item -ItemType Directory -Force -Path $localJob | Out-Null

$prompt = @"
You are a delegated AI agent (id: codex on $HostAlias). You cannot see the original conversation.
Your working folder is: $rdirWin  (stay inside it; put deliverables in the out\ subfolder)
1. Read RULES.md in this folder first and obey it.
2. Then read SPEC.md in this folder and do exactly what it says.
   Files the spec mentions with local D:\ or G:\ paths do not exist on this PC: use the copies uploaded into this folder.
3. Write your final report to REPORT.md in this folder. The first 10 lines MUST follow the summary format in RULES.md.
4. Your agent id for backup file names is: codex_$HostAlias
Write the report in Traditional Chinese. If you cannot finish, still write REPORT.md with status BLOCKED.
Do not open any window, do not use schtasks, do not touch other running processes.
"@
$promptFile = Join-Path $localJob 'PROMPT.md'
[IO.File]::WriteAllText($promptFile, $prompt, (New-Object Text.UTF8Encoding($false)))

Write-Host "job      : $jobId"
Write-Host "remote   : $HostAlias  $rdirWin"
& ssh @sshOpt $HostAlias "mkdir `"$rdirWin\out`"" | Out-Null
& scp @sshOpt -q $promptFile "${HostAlias}:$rdirUrl/PROMPT.md"
& scp @sshOpt -q $rules "${HostAlias}:$rdirUrl/RULES.md"
& scp @sshOpt -q $Spec "${HostAlias}:$rdirUrl/SPEC.md"
foreach ($f in $Upload) {
    $item = (Resolve-Path -LiteralPath $f).Path
    Write-Host "upload   : $item"
    & scp @sshOpt -q -r $item "${HostAlias}:$rdirUrl/"
}

$flags = if ($Full) { '--dangerously-bypass-approvals-and-sandbox' } else { '-s workspace-write' }
if ($Model) { $flags += " -m $Model" }
# stdin redirect keeps the Chinese prompt out of the command line
$remoteCmd = "cd /d $rdirWin && codex exec $flags --skip-git-repo-check -o last_message.txt - < PROMPT.md > run.log 2>&1"
$started = Get-Date
$job = Start-Job { param($o, $h, $c) & ssh @o $h $c; $LASTEXITCODE } -ArgumentList (, $sshOpt), $HostAlias, $remoteCmd
if (-not (Wait-Job $job -Timeout ($TimeoutMin * 60))) {
    Write-Host "TIMEOUT after $TimeoutMin min - stopping ssh (remote codex may need a manual check on $HostAlias)"
    Stop-Job $job
    $exit = 'timeout'
} else { $exit = (Receive-Job $job | Select-Object -Last 1) }
Remove-Job $job -Force
$secs = [int]((Get-Date) - $started).TotalSeconds
Write-Host "exit     : $exit  ($secs s)"

$ErrorActionPreference = 'Continue'   # a missing file on the remote must not abort the pull
foreach ($f in 'REPORT.md', 'run.log', 'last_message.txt') {
    & scp @sshOpt -q "${HostAlias}:$rdirUrl/$f" (Join-Path $localJob $f) 2>$null
}
& scp @sshOpt -q -r "${HostAlias}:$rdirUrl/out" $localJob 2>$null
$report = Join-Path $localJob 'REPORT.md'
Write-Host "pulled to: $localJob"
if (Test-Path $report) {
    Write-Host '---- first 10 lines ----'
    Get-Content -LiteralPath $report -TotalCount 10 -Encoding UTF8
} else {
    Write-Host 'REPORT   : (none) see run.log'
}
Write-Host "remote copy kept at $HostAlias : $rdirWin  (delete it when no longer needed)"
