---
name: dotnet-wpf-desktop-dev
description: >
  Hard-won gotchas and working patterns for building, debugging, and packaging
  Windows desktop apps in C#/WPF on .NET 8+, learned from actually shipping a
  full multi-tab WPF app end to end. Covers a critical Edit/Write-tool bug
  where icon-font glyph characters silently vanish from C# string literals,
  WinForms/WPF namespace collisions, running dotnet build/publish when the SDK
  is installed without admin rights, a recurring Release-publish cache bug,
  why WPF blocks Trimming and Native AOT (so don't waste time chasing them),
  why WindowChrome custom title bars are unreliable in automated/remote test
  environments (use DwmSetWindowAttribute instead), verified Segoe MDL2/Fluent
  icon codepoints, and realistic self-contained publish size expectations.
  Use this proactively any time the task involves writing, editing, debugging,
  building, or packaging a WPF/.NET desktop application — including when the
  user says things like "C# desktop app", "Windows GUI tool", ".NET publish",
  "XAML", "WPF", or is building a Windows utility/toolbox app — even if they
  don't name WPF explicitly.
---

# .NET / WPF Desktop App Development

This skill exists because a single WPF project produced the same handful of
expensive, non-obvious bugs over and over. Read this before writing WPF/XAML
code so you don't rediscover them the hard way.

## 1. Icon-font glyphs silently vanish from C# string literals — read this first

Segoe MDL2 Assets / Segoe Fluent Icons glyphs live in the Private Use Area
(U+E000–U+F8FF). When you write one of these characters *directly* (as a
literal glyph, not an escape sequence) into a C# string via the Edit or Write
tool, **the character is silently stripped and the string ends up empty** —
no error, no warning. This happened repeatedly and produced blank buttons and
runtime confusion that looked like unrelated bugs.

**The fix**: always write these as `\uXXXX` escape sequences typed out as
plain ASCII (backslash, u, four hex digits) — never paste or type the actual
glyph character into a C# file. XAML is fine either way (`&#xE768;` entities
in XAML never had this problem — only C# string literals did).

After writing any icon glyph into a `.cs` file, verify it actually landed:

```
node -e "console.log(JSON.stringify(require('fs').readFileSync('File.cs','utf8').split('\n')[LINE-1]))"
```

If the string shows as `""` instead of the expected escape sequence, it got
stripped. Fix it with `scripts/fix_glyph_literal.js` (see below) rather than
re-editing by hand — hand-editing tends to trigger the same stripping again.

XAML entities (`&#xE768;`) are unaffected — only literal PUA glyphs inside
C# string literals are the problem.

## 2. WinForms/WPF namespace collisions

A WPF project that also references `System.Windows.Forms` (e.g. for
`FolderBrowserDialog`) will get ambiguous-reference compile errors on types
that exist in both namespaces: `Application`, `MessageBox`, `UserControl`,
`MouseEventArgs`, `MouseButtonEventArgs`, `KeyEventArgs`, `Path`, `Brush`,
`Brushes`. Alias them explicitly at the top of any file that hits this,
rather than fully-qualifying every use:

```csharp
using MessageBox = System.Windows.MessageBox;
using UserControl = System.Windows.Controls.UserControl;
using MouseEventArgs = System.Windows.Input.MouseEventArgs;
using KeyEventArgs = System.Windows.Input.KeyEventArgs;
```

Add the alias for whichever specific type the compiler flags — don't
pre-emptively alias everything, since not every file hits every collision.

## 3. `dotnet build`/`publish` when the SDK has no admin-rights install

If the .NET SDK was installed without admin rights, it typically lives under
`%LOCALAPPDATA%\Microsoft\dotnet` instead of `C:\Program Files\dotnet`, and
that empty muxer in Program Files will make bare `dotnet` commands fail with
"no SDKs found". Each fresh shell needs the real location prepended to PATH
— **this does not persist between separate tool calls**, so set it every time:

```powershell
$env:PATH = "$env:LOCALAPPDATA\Microsoft\dotnet;$env:PATH"
$env:DOTNET_ROOT = "$env:LOCALAPPDATA\Microsoft\dotnet"
```

For a framework-dependent (non-self-contained) build launched by
double-clicking or by `Start-Process`, `DOTNET_ROOT` must also be set in that
process's environment or you'll see "You must install or update .NET to run
this application" even though the SDK is present — the exe host looks for a
system-wide install unless told otherwise.

## 4. Release publish serves a stale icon/resources after a csproj change

Changing `ApplicationIcon` (or other Win32 resource settings) in the `.csproj`
and then running `dotnet publish` can silently keep the old icon baked in —
the incremental build cache doesn't always notice. If a resource that should
have changed didn't, do a clean rebuild first:

```powershell
Remove-Item obj, bin -Recurse -Force -ErrorAction SilentlyContinue
dotnet publish -c Release -r win-x64 --self-contained true `
  -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o publish
```

## 5. WPF cannot use Trimming or Native AOT — don't chase this

Both `PublishTrimmed` and Native AOT require statically-analyzable code with
no runtime reflection. WPF's XAML/BAML loading is fundamentally reflection-based,
so **neither is supported for WPF**, on .NET 8 or 9. This isn't a missing flag
or misconfiguration — don't spend time trying to get it working. A
self-contained single-file WPF publish is realistically **~150–160MB**
regardless of app complexity, because that size is almost entirely the
bundled CoreCLR runtime + WPF's native DirectX-based rendering libraries
(`wpfgfx_cor3.dll`, `PresentationNative`, etc.), not the app's own code.

If bundle size genuinely matters more than developer time, the realistic
alternative is migrating to **Avalonia UI** (similar XAML+C# model, real
Trimming/AOT support) — not tweaking WPF publish flags, and not switching to
WinForms (marginal size win, loses modern styling capability).

Framework-dependent publish (rely on a system-installed runtime instead of
bundling it) shrinks the exe to a few MB, but then the target machine needs
the matching .NET Desktop Runtime installed separately (~55MB installer,
normally needs admin rights) — a real tradeoff, not a free win.

## 6. WindowChrome (custom title bars) is unreliable — use DwmSetWindowAttribute instead

Attempting a fully custom-drawn title bar via `WindowStyle="None"` +
`WindowChrome.WindowChrome` produced two failure modes in an automated/remote
test environment: caption-area buttons that existed in the visual tree but
never rendered, and — after a config tweak that's supposed to be a standard
fix (`GlassFrameThickness="0,0,0,1"` instead of `"0"`) — the window collapsing
to a broken ~156×24 size. This points at DWM composition being degraded or
unavailable in that environment, which WindowChrome depends on directly.

**For a themed dark title bar without full custom chrome risk**, use the far
safer `DwmSetWindowAttribute` / `DWMWA_USE_IMMERSIVE_DARK_MODE` (attribute 20)
call instead. This keeps the *native* title bar (native drag/resize/snap,
zero custom layout code) but asks DWM to paint it dark — no WindowChrome
involved, so the same composition dependency doesn't bite:

```csharp
using System.Runtime.InteropServices;
using System.Windows.Interop;

[DllImport("dwmapi.dll")]
private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attribute, ref int value, int valueSize);
private const int DwmwaUseImmersiveDarkMode = 20;

// in the Window's constructor:
SourceInitialized += (_, _) =>
{
    var hwnd = new WindowInteropHelper(this).Handle;
    int useDark = 1;
    DwmSetWindowAttribute(hwnd, DwmwaUseImmersiveDarkMode, ref useDark, sizeof(int));
};
```

Requires Windows 10 1809+ / Windows 11 (an OS requirement, unrelated to the
.NET version). If a fully custom title bar is still wanted later, treat it as
a genuinely risky feature to prototype and verify carefully on the user's
real machine before committing — don't assume a dev/test environment's DWM
behavior matches a normal desktop.

## 7. Verified icon glyph codepoints

See `references/segoe-icons.md` for a table of Segoe MDL2/Fluent glyph
codepoints already verified against Microsoft's documentation (folder, video,
music, play/pause, chevrons, etc.) — reuse these instead of guessing a
codepoint, since a wrong PUA codepoint renders as nothing or a fallback box
with no error.

Set the font as a fallback chain, not just Fluent Icons alone, since Segoe
Fluent Icons is Windows 11-era and may not exist on Windows 10:

```xml
FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets"
```

## 8. Known unresolved risk: custom ListBox templates can silently fail to render

At one point, adding a second overlapping child (an empty-state placeholder)
to a custom `ListBox` `ControlTemplate` — even a trivial solid-color `Border`
with no bindings or triggers — simply never appeared on screen, while the
exact same markup as the *entire* template (no nesting) rendered fine. This
was never fully root-caused; it may be specific to a particular rendering
environment rather than a general WPF limitation. If you hit something
similar (a template change that should obviously work but silently doesn't,
with no exception and a confirmed-correct visual tree via UI Automation),
don't sink excessive time into it — revert to the last known-working template
and consider a structurally different approach (e.g., a completely separate
overlay element instead of extending the existing template) rather than
continuing to debug the same shape of change.

## 9. Verifying UI changes without a working screenshot pipeline

Screenshot capture (`PrintWindow`) can intermittently return a blank/stale
image for a window's client area even though the app is running correctly —
this showed up after aggressive resize/maximize automation sequences, and
occasionally on a plain fresh launch. Before concluding a UI change is
broken, cross-check with UI Automation (confirm the expected elements exist,
have sane bounding rectangles, and contain the expected text) — a real crash
leaves a stack trace in stderr and/or a UI Automation tree that's genuinely
empty or wrong, whereas a capture artifact leaves a fully correct, populated
tree behind a blank screenshot. Don't repeatedly retry the same capture
approach hoping it resolves itself — switch to tree inspection instead.

## Bundled resources

- `references/segoe-icons.md` — verified Segoe MDL2/Fluent icon codepoints
- `scripts/fix_glyph_literal.js` — Node script to fix a stripped PUA glyph
  literal in a `.cs` file by line-matching and rewriting with a `\uXXXX`
  escape, used as in §1
