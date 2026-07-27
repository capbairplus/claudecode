---
name: solis-infrastructure-topology
description: "CRITICAL — the real solistex.com production/dev host is a SEPARATE machine (192.168.1.7) reached via SSH, not the local machine the Claude Code session runs on"
metadata: 
  node_type: memory
  type: project
  originSessionId: ecbf5e18-997e-4be8-bc69-00de39bf5803
  modified: 2026-07-26T13:36:17.169Z
---

**The machine this Claude Code session's Bash/PowerShell tools run on (hostname `CAPBAIR31`, IP `192.168.3.31`) is NOT the Solis WordPress host**, even though it confusingly has its own local `C:\wordpresstemp`, `C:\mysql`, `C:\php`, `C:\Apache` with the same-looking paths, the same MySQL user (`capbair`), and even the same-named `temp` database. That local copy's real relationship to production was never fully resolved — treat it as untrustworthy for "is X deployed" questions.

**The real host for everything Solis/solistex.com is a separate physical Windows machine:**
- Hostname: `WIN-QJJ2KOV5K5O`
- IP: `192.168.1.7`
- Access: SSH as `capbair@192.168.1.7` — key-based auth already works from this session's `~/.ssh/` (no password needed, `ssh -o BatchMode=yes capbair@192.168.1.7 <command>` just works).
- This is where `C:\wordpresstemp` (production, `temp` DB), `C:\solistex-new` (new site, `solistexdb_new` DB), and `C:\solistex-test` (internal test copy, `solistexdb_test` DB, port 8081, LAN-only) all actually live.
- Obsidian notes describing this host: `WordPress/www.solistex.com 維運現況.md`, `WordPress/MySQL 資料庫與帳號.md`, `WordPress/solistex-test 內部測試站.md`, `WordPress/Apache 虛擬主機設定.md`, `WordPress/備份與還原.md`.

**Confirmed on 2026-07-26 via direct SSH check:** `C:\solistex-new` on 192.168.1.7 is a fully working, clean WordPress install (Plan 1 / WordPress-foundation Tasks 1–5 are DONE, not just code-on-a-branch): `wp-cli core is-installed` passes, `solistexdb_new` has a clean default 12-table schema, the `solistex-new.local` Apache LAN vhost is configured and returns HTTP 200. **Task 6 (isolation verification) also completed 2026-07-26** — all 7 checks pass, documented in `docs/runbooks/solis-foundation.md` (committed to git). Plan 1 is fully done.

**Plan 2 (`solis-fabric-content-model`) also completed and verified live the same day** — the `wordpress/plugins/solis-fabric-model` plugin (fabric post type, 5 taxonomies, ACF field groups, product_code uniqueness, REST lockdown for MOQ/Lead Time) is deployed and active on `C:\solistex-new`, 23/23 PHPUnit tests passing. Deployment pattern used throughout: edit locally in the git repo (`G:\claudecode\Solis Website\wordpress\plugins\...`), then `scp`/`ssh` the same files to `C:\solistex-new\wp-content\plugins\...` on 192.168.1.7 and verify live via `wp eval-file`. No git checkout of this repo exists on the remote host — deployment is always a manual file copy, not a `git pull`.

**Two things found during Plan 2, worth knowing:**
1. ~~Pretty `/wp-json/` REST URLs 404 site-wide~~ — **corrected 2026-07-26 (Plan 4 Task 4):** this was never a platform-wide quirk. `C:\solistex-new\.htaccess` simply never existed (`wp rewrite flush --hard` silently fails to write it in this environment), so *every* pretty URL 404'd, not just REST — Pages, custom post types, everything except the root. Fixed by writing the standard WordPress rewrite block directly to `.htaccess`; see `docs/runbooks/solis-foundation.md` "Known fixes applied after initial provisioning". Production was never touched/affected. If `solistex-new` (or any future site on this host) ever gets rebuilt, check for this again — don't assume `wp rewrite flush` alone is enough.
2. ACF Free 6.8.6 does not auto-populate the `acf` key in REST responses (always empty `[]`) — public field REST exposure will need explicit `register_rest_field()` calls when that's built (likely `solis-fabric-catalog`). This one is still accurate/unresolved.

**Plan 4 (`solis-design-system-theme`) in progress** — a from-scratch theme at `wordpress/themes/solis/`, design tokens approved via a published mockup (navy/off-white/slate + logo-derived orange accent, system sans + monospace for technical data). As of 2026-07-26: Tasks 1-4 done (scaffold+tokens, header/footer/nav, Home page with a real uploaded product photo, About page with real team/company copy), all verified live. Tasks 5 (Sustainability) and 6 (responsive/a11y QA — blocked on the user adding a `solistex-new.local` hosts entry somewhere with browser access, deferred for now) remain.

**Plan 3 (`solis-csv-importer`) also completed and verified live 2026-07-26** — a second isolated plugin, `wordpress/plugins/solis-fabric-csv-import`, depending on `solis-fabric-model`. Full pipeline (parse → plan/preview → formula-injection guard → batch write with per-row isolation → WordPress writer → batch history → admin upload UI) verified live: empty-cell no-overwrite, `__CLEAR__`, multi-term taxonomies, real Fabric creation, batch history round-trip, admin capability check, and the confirm step all confirmed against the real host. 34/34 tests passing. Found and fixed a gap from Plan 3's own Task 1: the CSV fixed-header list had no column mapped to `post_title` at all — added `fabric_name`.

Next per the plan sequence: `solis-design-system-theme`.

**Why this matters:** on 2026-07-26 I burned a lot of the user's patience by checking only the local machine and Obsidian's plan-status field, concluding "Plan 1 hasn't been executed yet" — which was wrong because I was looking at the wrong machine entirely. The user had to explicitly tell me twice ("去 obsidian 查 192.168.1.7" / "用 SSH 操作 192.168.1.7 那台電腦") before I found the `WordPress/` ops folder in Obsidian and actually SSH'd in to check.

**How to apply:**
- Any time you're about to check whether something is installed/deployed/working for this project, or about to install/deploy/run something new, first ask: **which host does this need to happen on — this local session machine, or `192.168.1.7`?** Default assumption should be `192.168.1.7` for anything WordPress/Apache/MySQL/site-related, not the local machine, unless there's specific evidence otherwise.
- Read the `WordPress/` folder in Obsidian (not just `new soliswebsite/`) before concluding anything about server/infra state.
- To check or act on the real host: `ssh -o BatchMode=yes capbair@192.168.1.7 "<command>"` (plain command exec is safe — it does not create a visible window on the physical console; that risk is specifically about `schtasks`-style interactive-session launches per the user's global CLAUDE.md, not normal SSH exec).
- Never assume local `C:\wordpresstemp` on this session's machine reflects the real site's current state.
