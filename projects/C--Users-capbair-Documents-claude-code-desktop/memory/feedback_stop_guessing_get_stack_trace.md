---
name: feedback-stop-guessing-get-stack-trace
description: "When a bug's root cause isn't obvious after one theory fails, stop proposing more guesses — get a real stack trace or other hard evidence before the next fix attempt."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d7f81d1e-79df-4004-859f-fb312edcf186
---

Don't chain multiple "maybe it's X, let me rebuild and check" guesses in a row when a bug is silent (no visible exception). After the first guess-and-rebuild cycle fails to fix it, switch immediately to adding real diagnostics — log the full exception (`ex.ToString()`, not `ex.Message`) or otherwise get a stack trace — before proposing another fix.

**Why:** During the [[ffmpeg-toolbox-app]] thumbnail bug, two guessed fixes in a row (a WIC image-cache theory, then a startup-race theory alone) were shipped and rebuilt without hard evidence, and both turned out incomplete/wrong in isolation. The user called this out directly: "你搞了三次，還搞不定?????" and "你可以先 focus 在現在的問題嗎?". The very next step — logging the full exception stack trace instead of the message — found the actual root cause (a WPF `BitmapImage`/`IgnoreImageCache` bug) in one pass.

**How to apply:** The very first time a fix attempt doesn't resolve a silently-failing bug, the next action should be adding/reading diagnostics (full exception text, log panel contents, stack traces), not another theory-driven rebuild. This applies to any project, not just WPF — the pattern is: one free guess is reasonable, a second guess without new evidence is not.
