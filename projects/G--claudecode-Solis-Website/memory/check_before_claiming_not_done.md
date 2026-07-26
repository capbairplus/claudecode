---
name: check-before-claiming-not-done
description: "Before saying a plan/feature \"hasn't been done yet\" in this project, check Obsidian AND all git branches, not just the current branch and filesystem"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ecbf5e18-997e-4be8-bc69-00de39bf5803
  modified: 2026-07-26T08:51:29.326Z
---

Before concluding that some piece of work for this project hasn't been started or done, check **both**:

1. **The Obsidian vault** (`new soliswebsite/` folder, via the Obsidian MCP tools) for planning notes and status fields.
2. **All git branches**, not just `master`/current branch — run `git branch -a` and `git log --all --oneline` (or search branch names/commits for the relevant keyword). Check `git diff master <branch> --stat` to see what exists there.

**Why:** on 2026-07-23 I told the user `solistexdb_new` / the WordPress foundation (Plan 1) "hadn't been done yet" based only on checking the filesystem (`C:\solistex-new` absent) and Obsidian (status still said "ready for execution"). The user was angry — this project has a strong established pattern (see also [[new-solis-website-content-status]] re: the AI Robot plugin) of real, substantial work landing on unmerged `feature/*` branches that never get surfaced unless you actually go look. In this case `feature/solis-wordpress-foundation` did exist with real provisioning/install PowerShell scripts and Pester safety tests (commits dated 2026-07-21) — I had missed it entirely before answering. (After checking that branch, the DB/site still genuinely don't appear to exist on disk — no `$env:LOCALAPPDATA\Solis` credential files, no `C:\solistex-new` — so the branch's scripts were apparently written and tested but never actually executed. But I should have surfaced the branch's existence before asserting anything, not just the filesystem conclusion.)

**How to apply:** any time you're about to say "X isn't done" or "we haven't started X" for this project, run a quick `git branch -a` / `git log --all --oneline --grep=<topic>` sweep and an Obsidian search first. Report what you find even if the underlying infrastructure still turns out to be un-executed — the existence of a stale feature branch changes the next step (review/cherry-pick it) versus starting from scratch.
