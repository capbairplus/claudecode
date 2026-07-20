---
name: ffmpeg-toolbox-app
description: "WPF ffmpeg GUI toolbox project — location, tech stack, build/publish quirks, and design conventions established so far."
metadata: 
  node_type: memory
  type: project
  originSessionId: d7f81d1e-79df-4004-859f-fb312edcf186
---

Building a Windows ffmpeg GUI toolbox app for the user at
`G:\claudecode\ffmpeg-app_2026-07-15\FfmpegToolbox\` (C# / WPF / .NET 8, `net8.0-windows`).

**Why:** User wanted a native Windows app (chose C#/WPF over Python) to wrap common ffmpeg operations (merge, extract audio, extract frames, images-to-video, trim, GIF, compress, rotate/flip, video+mp3 merge, MP3 smart-split) behind a friendly UI, without hand-typing ffmpeg commands each time.

**Environment quirks (How to apply — re-check if build/publish breaks again):**
- No system-wide .NET SDK was installed; installed .NET 8 SDK per-user at `%LOCALAPPDATA%\Microsoft\dotnet` (no admin rights available). `C:\Program Files\dotnet` has an empty/stub muxer with no SDK — always prepend `%LOCALAPPDATA%\Microsoft\dotnet` to PATH before running `dotnet` commands, e.g. `export PATH="/c/Users/capbair/AppData/Local/Microsoft/dotnet:$PATH"`.
- The published self-contained exe needs `DOTNET_ROOT` set to that same path to run standalone if double-clicked before the runtime is otherwise resolvable — but the shipped build is `--self-contained true -p:PublishSingleFile=true`, so end users don't need any of this; it bundles its own runtime.
- ffmpeg/ffprobe already exist on this machine at `C:\Users\capbair\Videos\ffmpeg\bin\` and are auto-detected by the app on launch.
- Publishing (`dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o publish`) fails with a file-lock error if a previous build of `FfmpegToolbox.exe` is still running — user has given standing permission to just `taskkill //IM FfmpegToolbox.exe //F` without asking first.
- After changing `ApplicationIcon` in the csproj, an incremental `dotnet publish` for the Release/win-x64 single-file target silently kept the OLD icon (stale intermediate objects) even though a plain `dotnet build` (Debug) picked it up correctly. Fix: delete `obj/` and `bin/` before republishing when the icon (or other Win32 resource) doesn't seem to update.
- The app's own window/taskbar icon can also lag behind due to Windows Explorer's icon cache — tell the user to press F5 in Explorer if the exe's actual embedded icon (verified via `[System.Drawing.Icon]::ExtractAssociatedIcon`) is already correct.

**Bugs found and fixed (real root causes, for reference if similar symptoms recur):**
- Merge tab's icon-view thumbnails rendered as solid black boxes. Took 3 rebuild cycles to nail down — root cause turned out to be TWO stacked bugs, not one:
  1. **Startup race condition**: `MainWindow`'s constructor called each tab's `Initialize()` (which, for Merge tab, auto-loads the last-remembered source directory and immediately kicks off background thumbnail generation) BEFORE `FfmpegLocator.TryAutoLocate()` had run (that call was in the `Loaded` event, which fires later). Every thumbnail attempt failed instantly because `FfmpegLocator.IsReady` was still false. Fix: call `FfmpegLocator.TryAutoLocate(_settings)` in the constructor, before any tab `Initialize()`.
  2. **WPF `BitmapImage` bug**: loading a thumbnail via `StreamSource` (a `MemoryStream`) together with `CreateOptions = BitmapCreateOptions.IgnoreImageCache` throws `ArgumentNullException: Value cannot be null. (Parameter 'key')` deep inside `BitmapImage.FinalizeCreation() → ImagingCache.RemoveFromCache(Uri, Hashtable)` — WPF's internal cache-eviction path assumes a non-null `Uri` and only skips that path when `IgnoreImageCache` is NOT set. Fix: drop `IgnoreImageCache` when using `StreamSource`; `UriSource` loading never had this problem in the first place.
  - **How to apply:** if a WPF image/resource silently fails to render with no visible error, don't guess — catch the exception with `_host.AppendLog($"...: {ex}")` (full `ex.ToString()`, not just `.Message`) to get the real stack trace before proposing a fix. Guessing burned 2 wasted rebuild cycles here; the stack trace found the real cause in one shot.
  - Also: force-killing the exe (`taskkill /F`) skips the WPF `Closing` handler, so `SettingsService.Save` never runs and any settings changed that session (like `LastMergeSourceDir`) are lost on the next launch — expected, not a bug, but easy to mistake for one mid-debugging.

**Design conventions established with the user (apply to any new tab/feature added later):**
- Every Generate button must work with NO output location chosen — default to the input file's own directory. Explicit output picker buttons are always optional.
- Every successful Generate should auto-open the output folder in Explorer (`ShellHelper.OpenFolderAndSelect` / `OpenFolder`), not show a blocking "success" MessageBox.
- Every file-selection surface (single file, batch list, source-dir list) should also accept drag-and-drop from Explorer.
- See [[feedback-folder-link-on-deliverable]] for the folder-link habit that applies when handing over builds of this app.
