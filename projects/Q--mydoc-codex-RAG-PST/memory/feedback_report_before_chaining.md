---
name: feedback-report-before-chaining
description: "User wants a status report after completing a requested piece of work before starting the next piece, not silent chaining into further edits"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 43f4933d-a028-41d2-8c7b-ac38a29d27ef
  modified: 2026-08-12T14:26:34.955Z
---

When the user asks for a specific deliverable (e.g., "update the docs"), report back what was done as soon as that piece is complete — do not silently continue into a second, related file/task without checking in first, even if the next step seems like an obvious continuation.

**Why:** During a long autonomous RAG-PST session (2026-08-12), after being asked to update documentation, the assistant updated `TASKS.md` and then immediately moved on to editing `docs/project-history-and-roadmap.md` without pausing to report progress. The user interrupted: "我剛才叫妳寫文件, 你不是應該先跟我回報?" (I just asked you to write documentation, shouldn't you report back to me first?).

**How to apply:** After finishing a discrete unit of work the user asked for, stop and give a concise status update — what changed, what's still pending — before starting the next file or task, even within the same broader request. This applies especially in extended/auto-mode sessions where it's tempting to keep chaining actions. Ask before continuing to the next piece rather than assuming silent continuation is welcome, particularly for documentation/writing tasks where the user may want to redirect scope (e.g., they redirected "also write it to Obsidian" toward a specific vault path, `D:\capbairvault`, rather than assuming the repo's own docs/ folder was sufficient).

Related: [[project-rag-pst-context]] if it exists — this project has an Obsidian vault at `D:\capbairvault\RAG\PST\` that mirrors (and is the original, pre-corruption source of) the repo's `docs/project-history-and-roadmap.md`.
