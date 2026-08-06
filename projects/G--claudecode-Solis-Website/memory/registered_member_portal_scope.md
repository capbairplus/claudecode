---
name: registered-member-portal-scope
description: "Decided scope for the first external user-management deliverable: Registered-tier login gating fabric specs + inquiry management, NOT full B2B store — design spec written 2026-08-05, not yet implemented"
metadata:
  type: project
  originSessionId: 387ca500-541e-42dc-b543-172226d3e93a
  modified: 2026-08-05T13:25:24.300Z
---

On 2026-08-05 the user decided the first external "user management" deliverable is a **narrow slice**, not the full B2B store: registered-member login unlocks fabric technical specs (composition/weight/width/full description/datasheet PDF — same fields the old solistex.com site locks behind login), plus an inquiry form + admin-side inquiry management with in-app reply. Explicitly NOT in scope yet: order conversion/tracking, tiered pricing, cart, checkout, payment, customer dashboard, sample requests, fabric variations.

Key decisions locked in during brainstorming:
- Registration: admin/sales manual approval (not open self-serve) — new accounts start `pending_approval`, only usable after a staff member approves.
- Inquiry backend: full management (list + detail + in-app reply + email notifications), not just an email-and-forget capture. But no Order CPT and no inquiry→order conversion for now.

This narrows (but does not replace) the earlier full spec [[Solis B2B Inquiry & Order System]] (2026-07-27, L2/L3, still in Obsidian, still valid as the reference for when a real B2B store is eventually needed).

**Where the spec lives:** `new soliswebsite/Solis Registered Member Portal & Inquiry Management.md` in Obsidian (design-specification, status: draft, written 2026-08-05). It defines two new isolated WordPress plugins to build (`solis-member`, `solis-inquiry`), the registration/approval workflow, how it hooks into the already-existing-but-unused `VisibilityFieldGroup`/`PublicFabricProjection` reserved-permission scaffolding in `solis-fabric-model`, and 4 open questions still needing the user's answer (bulk-lock existing 17 fabrics to Registered now vs. later; whether inquiries get assigned to specific sales reps; which inbox gets registration-approval notifications; whether to send a rejection email).

Also updated: `new soliswebsite/Solis Website Next Tasks.md` P4 items 14–15 now point to this new spec and reflect the narrowed scope. A dated note was added atop [[Solis B2B Inquiry & Order System]] pointing forward to this narrower spec.

**Why this matters:** as of 2026-08-05 this is spec-only — no code exists yet (`wordpress/plugins/` only has `solis-fabric-model`, `solis-fabric-csv-import`, `solis-news-aggregator`; confirmed via `git branch -a` that no inquiry/member/b2b work exists on any branch either). Don't assume this is built just because a thorough spec exists — check the plugins directory and git branches before claiming implementation status, per [[check-before-claiming-not-done]].

**How to apply:** when this project's "user management" / "會員" / "B2B" / "inquiry" work comes up again, read this spec first before re-brainstorming from scratch — the scope decisions above are already made, only the 4 open questions in the spec's section 11 remain. If implementation has started since this memory was written, verify current state in `wordpress/plugins/solis-member/` and `wordpress/plugins/solis-inquiry/` rather than trusting this memory's "not yet implemented" claim.
