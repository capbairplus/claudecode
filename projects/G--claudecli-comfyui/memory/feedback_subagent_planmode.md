---
name: feedback-subagent-planmode
description: Subagents spawned via the Agent tool for multi-file coding tasks may get stuck in a plan-only mode with no ExitPlanMode tool to escape it
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 34985248-288c-4572-8ef9-f78b30d96a47
  modified: 2026-09-30T10:06:59.631Z
---

When dispatching general-purpose subagents (via the Agent tool) for non-trivial multi-file implementation work, they may do full research, write a detailed plan to `C:\Users\capbair\.claude\plans\<parent-plan-name>-agent-<id>.md`, and then stop and ask "should I proceed?" instead of implementing — even when the prompt never asked them to plan first. A harness-level "Plan mode is active" system-reminder can fire inside the subagent's own context, restricting it to read-only actions plus edits to its plan file. Critically, **the `ExitPlanMode` tool is not available to these subagents** (confirmed via `ToolSearch` returning no match) — so telling the subagent "you have my sign-off, proceed" does nothing; the restriction is enforced at the tool layer, not by conversational instruction, and there is no in-subagent way to lift it.

**Why:** Discovered 2026-09-30 while orchestrating a 5-agent parallel mobile-redesign task on `workflowui-csharp-poc`. Every subagent given a multi-file coding task independently hit this wall after finishing research, despite prompts that said nothing about planning first.

**How to apply:** When a dispatched subagent reports back with a finished plan instead of finished edits, don't keep messaging it asking it to proceed — that wastes turns and may even get blocked by the auto-mode permission classifier (a message that reads like "bypass this restriction" can itself be denied). Instead, **read the subagent's plan file directly** (it's a normal file, fully readable) and **execute the edits yourself** in the coordinating session — the coordinator is not subject to the same per-subagent plan-mode gate. This preserves all the subagent's research/planning value without needing it to survive to execution. See [[project_comfyuicard_mobile_redesign]] for a concrete case where this pattern played out across 5 parallel agents.
