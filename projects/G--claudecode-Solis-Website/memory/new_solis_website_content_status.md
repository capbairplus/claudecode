---
name: new-solis-website-content-status
description: "Content-gathering status for the New Solis Website project as of 2026-07-23 — what's confirmed vs. still blocked"
metadata: 
  node_type: memory
  type: project
  originSessionId: ecbf5e18-997e-4be8-bc69-00de39bf5803
  modified: 2026-07-26T11:37:56.342Z
---

Full detail lives in the Obsidian note `new soliswebsite/Website Content Checklist.md` (kept up to date there — check it for current status, this is a summary).

**Confirmed/gathered:**
- Company overview, mission, vision, founding year (1991), Chinese legal name 明興紡織有限公司, Taipei office address, contact email/phone, 17 team members (names+titles, no photos) — from `source/官網2021.9.10/` and the live solistex.com About page.
- Certifications, comprehensive: OEKO-TEX (2012–2025), GRS (through 2026), ISO 14001/45001/50001, OHSAS, BLUESIGN, ZDHC, Higg, SLCP, plus brand-audit certs (Adidas/Under Armour/Columbia) — in `source/證書/`.
- 17 unique fabric product codes from solistex.com public category listings, with public Function/Application/Sustainability taxonomy tags and 300×300 thumbnail images. The site's Application taxonomy (Baby/Casual/Fashion/Golf/Ski-Snow/Sport) matches the new design spec's planned taxonomy almost exactly.
- News & Exhibitions: 8 recurring exhibition names (Performance Days, ISPO Germany/Beijing, Intertextile Shanghai, Outdoor Retailer USA, Texfusion UK, Saigon Fabric EXPO, TITAS Taipei) — names only, no venue/booth/dates. Real photo+video material for AW26 Taipei Fashion Week in `source/五分鐘簡報/AW26-鑫囍-台北時裝週/`.
- Brand assets: see [[brand-decisions]].

**Still blocked / open:**
- **Fabric technical specs are locked**: composition, weight (gsm), width, full description, datasheet PDF for all 17 products require a logged-in account on solistex.com ("Restricted" page). I do not log in or handle credentials — this needs the user to either export via WooCommerce admin (Products → Export) or grant read access to the `temp` MySQL database.
- Manufacturing capability photos/descriptions (weaving, knitting, dyeing, lamination, bonding, coating) — not yet gathered, no photos found in source data.
- Sustainability policy narrative and quantified environmental results (water/energy/waste/carbon) — not yet gathered.
- Inquiry form requirements (fields, privacy wording, spam protection) — not yet confirmed with the user.

**Why this matters:** the New Solis Website design spec ([[brand-decisions]] plan) can't reach Stage 1 completion without the locked fabric technical data — that's the main remaining bottleneck, not the WordPress build itself.

**How to apply:** before doing Fabric-catalog design/content work, check whether the technical-spec blocker above has been resolved; if not, flag it rather than inventing placeholder specs.

**Correction (2026-07-26):** Plan 1 (WordPress foundation) is DONE — see [[solis-infrastructure-topology]]. `C:\solistex-new` is a fully working clean WordPress install on the real production host (192.168.1.7), verified via SSH: `core is-installed` passes, `solistexdb_new` has clean default tables, the `solistex-new.local` LAN vhost responds 200. Only Task 6 (isolation-verification script + runbook doc) is outstanding. Do not say Plan 1 "hasn't been done" — check the real host first.
