---
name: feedback-g-drive-edit-tool-fsync-failure
description: "The Edit/Write tool fails with 'EUNKNOWN: unknown error, fsync' on files under G:\\claudecode\\ — use PowerShell file I/O instead. Check this before any file edit under G:\\."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 910137ab-1d24-4232-a39d-42fa2ff5b932
  modified: 2026-07-24T06:29:39.106Z
---

The `Edit` (and likely `Write`) tool intermittently but repeatedly fails with
`EUNKNOWN: unknown error, fsync` when editing files on `G:\` — the drive is
mounted as `DriveType=4` (network) with `exFAT` filesystem (per
`wmic logicaldisk where "DeviceID='G:'" get DriveType,FileSystem`), and exFAT
network shares commonly don't support the fsync call the tool issues after
writing. The call reports failure and, critically, **the edit does NOT
apply** — the file is left unchanged, silently, unless you verify.

**Why this matters:** hit this 4 times in a row in the
[[project_ytdlp_toolbox_app]] session (2026-07-19) editing both `.xaml` and
`.cs` files under `G:\claudecode\ytdlp-app_2026-07-19\`. Each failure looked
identical and retrying the same Edit call just failed the same way — it is
not transient, it is systematic to this drive.

**How to apply:** When an `Edit`/`Write` call on a path under `G:\` returns
`EUNKNOWN: unknown error, fsync`, don't retry the same tool call — switch
immediately to a PowerShell-based write, which does not hit this fsync path:

```powershell
$path = "G:\...\File.ext"
$content = Get-Content -Path $path -Raw -Encoding UTF8
$old = @'
...exact old text...
'@
$new = @'
...exact new text...
'@
if ($content.Contains($old)) {
    $content = $content.Replace($old, $new)
    [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($true)))
}
```

For a full-file rewrite, skip the `Get-Content`/`Replace` step and just
`[System.IO.File]::WriteAllText($path, $new, ...)` directly with the whole
new content. Always verify afterward (re-read or `Grep` for the new content)
since this workaround has no built-in confirmation the way the Edit tool
normally would. This affects every project under `G:\claudecode\`, not just
the yt-dlp app — check for this failure mode first any time an Edit call on
a `G:\` path errors, rather than re-diagnosing from scratch.

**Related but separate symptom (2026-07-24): `dotnet publish` fails on a
freshly-deleted `obj\`/`bin\`.** Running `Remove-Item obj, bin -Recurse
-Force` then immediately `dotnet publish` on this drive threw
`DirectoryNotFoundException` / `MSB3883` for intermediate files like
`obj\Release\...\ref\<Assembly>.dll` or `...\refint\<Assembly>.dll` —
different subfolder each time, not always reproducible, clearly a directory-
creation race on this exFAT network mount. **Workaround**: don't `dotnet
publish` straight after wiping `obj`/`bin`. Run a plain `dotnet build -c
Release` first (this reliably (re)creates the full intermediate directory
tree), *then* run `dotnet publish` on top of it (only delete the `publish`
output folder itself, not `obj`/`bin`). This resolved it every time it was
tried. The icon/resource-cache gotcha in the `dotnet-wpf-desktop-dev` skill
(§4) still calls for wiping `obj`/`bin` before a Release publish when a
`.csproj` resource setting changed — on this drive, follow that wipe with a
`dotnet build` first, not a direct `dotnet publish`.
