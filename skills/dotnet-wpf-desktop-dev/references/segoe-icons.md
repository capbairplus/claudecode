# Verified Segoe MDL2 Assets / Segoe Fluent Icons codepoints

Verified against Microsoft's official Segoe MDL2 Assets / Segoe Fluent Icons
documentation. Use these directly instead of guessing a codepoint — most
PUA codepoints that don't match a real glyph just render as nothing or a
fallback box, with no error to catch the mistake.

In XAML: `Text="&#xE8B7;"` (numeric character reference, safe to type directly).
In C#: `"\uE768"` (escape sequence, typed as plain ASCII text -- see the
main SKILL.md for why the literal glyph character must never be typed
directly into a C# string).

| Codepoint | Name | Typical use |
|---|---|---|
| E8B7 | Folder | folder picker button |
| E838 | FolderOpen | open folder action |
| E714 | Video | generic video |
| E768 | Play | play / generate / run |
| E769 | Pause | pause playback |
| EC4F | MusicNote | audio file / music tab |
| E767 | Volume | audio-related |
| EB9F | Photo2 | picture / frame extraction |
| E8B9 | Picture | image |
| E74D | Delete | delete / remove |
| E713 | Setting | settings / configure path |
| E8C6 | Cut | trim / cut |
| EA3C | MergeCall | merge action |
| E7AD | Rotate | rotate/flip |
| E710 | Add | add item |
| E74E | Save | save |
| E8A5 | Document | document/file |
| E895 | Sync | processing / transcode / compress |
| E72C | Refresh | refresh |
| E90B | MusicInfo | waveform / audio split |
| E7A8 | Crop | crop |
| E8B5 | Import | import |
| E722 | Camera | capture / GIF |
| E8AA | VideoChat | images→video (distinct from plain Video) |
| E740 | FullScreen | fullscreen toggle |
| E712 | More | overflow menu |
| E76B | ChevronLeft | previous / back |
| E76C | ChevronRight | next / forward |
| E80F | Home | home |
| E949 | Minimize | window minimize (custom title bar) |
| E739 | Maximize (ChromeMaximize) | window maximize |
| E923 | ChromeRestore | window restore (un-maximize) |
| E8BB | Close (ChromeClose) | window close |

No confirmed codepoint was found for "Compress/Zip" specifically — a
generic "Sync" (E895, implying transform/processing) was used as a
reasonable stand-in for a video-compression feature rather than guessing an
unverified PUA codepoint.
