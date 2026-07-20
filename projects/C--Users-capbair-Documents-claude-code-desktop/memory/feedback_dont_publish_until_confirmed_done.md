---
name: feedback-dont-publish-until-confirmed-done
description: "Don't run the self-contained publish/package step until the user explicitly confirms all pending changes are finished; proactively remind them to package once done."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d7f81d1e-79df-4004-859f-fb312edcf186
---

Don't proactively run `dotnet publish` (self-contained packaging) for the FFmpeg Toolbox app — or similar "final packaging" steps in any project — while there are still known unfinished changes or open feedback items. Wait for the user to confirm everything is done first.

**Why:** User rejected a publish-step tool call mid-session, saying "先不用..還沒全改好，你記得都改好了再提醒我要打包成一個自包含版本" (not yet, changes aren't all done — remind me to package once they are). Packaging is a wrap-up step, not something to bundle into an in-progress iteration.

**How to apply:** When a project reaches a natural "looks done" point but the user hasn't explicitly said so, ask or wait rather than auto-publishing. Once the user does confirm everything is finished, proactively remind them about packaging (don't wait to be asked) — see [[feedback_folder_link_on_deliverable]] for the related "always hand off deliverables clearly" pattern. This applies specifically to [[project_ffmpeg_toolbox_app]].
