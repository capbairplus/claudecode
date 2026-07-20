---
name: project-ytdlp-toolbox-app
description: "yt-dlp desktop WPF app project — location, bundled binaries, and design decisions. Load when the user mentions the yt-dlp app / YtDlpToolbox."
metadata: 
  node_type: memory
  type: project
  originSessionId: 910137ab-1d24-4232-a39d-42fa2ff5b932
---

Building a yt-dlp desktop GUI, sibling to [[project_ffmpeg_toolbox_app]], at
`G:\claudecode\ytdlp-app_2026-07-19\YtDlpToolbox\`. Deliberately reuses the
ffmpeg-app's WPF skeleton/theme/UX conventions (dark theme, DWM dark title
bar, GroupBox cards, status bar + log expander at bottom) per explicit user
request ("UI/UX 妳能抄 ffmpeg 就儘量抄").

**Bundled binaries** (copied into `ExternalTools\`, csproj copies them to
output `bin\` subfolder via `<Content Include="ExternalTools\**\*.*">` with
`<Link>bin\%(RecursiveDir)%(Filename)%(Extension)</Link>`):
- `yt-dlp.exe` — downloaded from official GitHub releases (user approved).
- `ffmpeg.exe` / `ffprobe.exe` — copied from the user's existing
  `C:\Users\capbair\Videos\ffmpeg\bin\` rather than re-downloaded.

`YtDlpLocator` checks bundled `bin\` next to the exe first, then
`AppSettings` saved paths, then PATH — mirrors `FfmpegLocator`'s pattern.

**Confirmed MVP scope** (all user-approved, 2026-07-19):
quality tiers (best/medium 720p/low 480p/audio-only with format+bitrate
choice), subtitles as separate .srt (not embedded), thumbnail embed, chapter
splitting, browser-cookie import, playlist URLs downloaded as a single queue
entry (yt-dlp handles playlist expansion internally — app does not
pre-enumerate playlist items), download-archive dedup file per output
folder (`.ytdlp-archive.txt`), auto-subfolder-by-uploader.

**Known gotcha already hit:** yt-dlp's `--print` template fallback operator
is `,` (`%(playlist_title,title)s`), not `|` — `|` means "print this literal
text if the field is empty," so a wrong guess silently printed the literal
word instead of falling back to another field. Verified via direct CLI test
against a real video before wiring into the app.

**Verification status:** CLI-level engine (yt-dlp+ffmpeg args, progress-line
regex, merge) verified against a real download. Full in-app GUI click-through
not yet verified — see [[windows_session_isolation_interactive_cli]] for why
computer-use couldn't reach the shell-launched process; ask the user to
double-click the exe themselves for a GUI walkthrough if issues come up.

**Two real-world failure modes hit during user testing (2026-07-19), both
confirmed via direct CLI reproduction, neither is an app bug:**
1. `HTTP Error 403: Forbidden` on some videos' actual format download (after
   format selection succeeds) — current (2026) YouTube anti-bot escalation:
   certain formats need signature/PO-token deciphering that requires a JS
   runtime, which yt-dlp's own warning names explicitly (`No supported
   JavaScript runtime could be found... add --js-runtimes RUNTIME[:PATH]`).
   **Fixed and confirmed 2026-07-19**: bundled a portable `deno.exe`
   (downloaded from denoland/deno GitHub releases, ~99MB, into
   `ExternalTools\`) and `YtDlpLocator.DenoPath` auto-detects it from the
   bundled `bin\` folder; `YtDlpArgsBuilder.Build` adds
   `--js-runtimes deno:<path>` whenever it's found. Re-tested the exact
   format (itag 399+251) that previously 403'd — now downloads successfully.
2. `--cookies-from-browser chrome` fails whenever Chrome is running (`Could
   not copy Chrome cookie database`, yt-dlp issue #7271) — added detection
   in `MainWindow.xaml.cs` for this pattern with a "close your browser"
   hint. **But closing Chrome fully revealed a deeper, unresolved issue**:
   `Failed to decrypt with DPAPI` (yt-dlp issue #10927) — Chrome v127+'s
   Application-Bound Encryption for cookies, which yt-dlp cannot reliably
   decrypt on this machine even with the browser fully closed. Firefox
   isn't actually used here (no profile found) and Edge hits the same
   Chromium DPAPI/ABE issue. **Fixed 2026-07-19** by adding a third cookie
   source option: `--cookies <file>` importing a user-exported cookies.txt
   (e.g. via the "Get cookies.txt LOCALLY" extension), which sidesteps the
   live-browser-decryption problem entirely. `AppSettings.CookieMode`
   ("none"/"browser"/"file") replaced the old `UseCookiesFromBrowser` bool;
   UI is now 3 radio buttons in the Cookie GroupBox.

**Debugging gotcha:** the app's log box accumulates across multiple separate
"開始下載佇列" clicks within one session (never cleared between runs) — when
reading a pasted log to diagnose an issue, check whether it's actually two
concatenated runs (e.g. an initial batch + a later retry with different
settings) before assuming everything belongs to one invocation. The
`"選擇輸出資料夾,使用預設下載資料夾"` line only logs once per session (first
time the fallback triggers), which is a useful anchor for spotting the
boundary between runs.
