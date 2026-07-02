---
name: feedback-verify-before-answering
description: "When unsure about software UI/feature details (e.g. 3ds Max, Unreal menus), search/verify before answering instead of guessing"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: dfc00a3e-4bef-4e1b-b15f-48c98e82ed83
---

When not confident about a technical detail — especially exact menu locations, feature availability, or whether a feature applies to a specific renderer/plugin combination — verify with WebSearch (or other lookup) before telling the user where to click or what to do. Do not guess and present it as fact.

**Why:** During the [[armor-lora-project]]-adjacent 3ds Max + Unreal Datasmith walkthrough session (2026-06-28), repeatedly guessed UI locations (e.g. claimed 3ds Max's "ActiveShade" would give a live V-Ray preview like Blender's viewport render). This was wrong — ActiveShade only supports Arnold/ART, not V-Ray; the correct feature is V-Ray's own IPR (Start IPR via Render Setup or VFB). The user explicitly called this out: "你又再胡猜了,寫入你的記憶,你沒把握的就去查資料". Earlier in the same session, guessed at Unreal↔3ds Max coordinate-axis conversion without verifying, which produced a blank/wrong render and wasted significant time before the user pushed back ("你等於什麼都沒做").

**How to apply:** Before answering "how do I do X in [software]" or asserting a feature exists/works a certain way, if there's any doubt, run a quick search to confirm the exact mechanism, especially when:
- The claim involves a specific renderer/plugin's compatibility (e.g. "does feature A support engine B")
- The claim is about exact menu paths/button names in unfamiliar software
- A previous similar guess in the conversation already turned out wrong

This applies broadly, not just to 3ds Max — same principle for Unreal Engine, or any GUI-heavy software the user is operating live while I give instructions.
