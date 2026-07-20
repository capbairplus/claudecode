---
name: feedback-folder-link-on-deliverable
description: "Always open the containing folder in Explorer AND give a markdown link whenever handing over a built file (exe, output artifact, etc.) — do not wait to be asked."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d7f81d1e-79df-4004-859f-fb312edcf186
---

When delivering a build output or generated file (e.g. a freshly built/published .exe), always:
1. Open the containing folder in File Explorer (`start "" "<folder>"` via Bash, or `explorer.exe "<folder>"`).
2. Include a markdown link to the file in the same message.

**Why:** During the [[ffmpeg-toolbox-app]] project, the user had to ask "為何又忘了給我 folder link?" multiple times in the same session after I handed over updated builds without opening the folder or linking it. This is a recurring friction point, not a one-off. It recurred again on 2026-07-19 in the new [[project_ytdlp_toolbox_app]] project: after a `dotnet build` success + first-run verification message, I again reported the deliverable without opening Explorer or linking the project folder — despite this memory already existing. The pattern survives across projects/sessions, so treat it as a hard checklist item, not a one-time reminder.

**How to apply:** Any time a turn ends with "here's your updated build/file" — including interim progress updates that mention a build succeeded or a file/folder now exists, not just a final polished handoff — check before sending: did I open the folder AND link the file/folder? Do both proactively, every time, without being asked. Treat "build succeeded" or "project scaffolded" messages the same as a final deliverable for this purpose.
