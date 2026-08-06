---
name: project-cbas-dotnet-rewrite
description: CBAS is being rewritten from FastAPI+React to ASP.NET Blazor Server + MySQL
metadata: 
  node_type: memory
  type: project
  originSessionId: 9e4d4635-bf8e-4009-a62e-009fbc56772e
  modified: 2026-08-05T17:13:59.767Z
---

User asked to rewrite the CBAS research workbench (`G:\Codex\CBAS`) as ASP.NET C#, in addition to the existing FastAPI (`backend/`) + React/Vite (`frontend/`) version. The two versions live side by side; the Python/React one was NOT deleted or touched.

Chosen architecture (via AskUserQuestion on 2026-08-05): **Blazor Server** (not Web API+React, not Blazor WASM, not Razor Pages MVC) + **MySQL via EF Core/Pomelo** (not SQLite, not SQL Server) + **core MVP first** (not full feature parity).

New project: `G:\Codex\CBAS\dotnet\CbasWorkbench\` (.NET 8, `dotnet new blazor --interactivity Server --empty`).

Scope implemented (as of 2026-08-06, third pass — full feature parity with the Python version): Bond CRUD, CSV/XLSX import (header-mapping logic ported from `backend/app/importer.py`), search/status filter, inline status+note editing, import batch history, 下單前檢查清單 (checklist, 9 fixed items), 營業員詢價紀錄 (broker quotes), 交易復盤 (trade reviews), TPEx OpenAPI auto-update (with preview + auto-refresh timer), password login (cookie-based, gated by `CBAS_APP_PASSWORD` env var), MySQL backup download (via `mysqldump`, replacing the Python version's SQLite-file download since this version uses MySQL), CSV/Markdown export. Everything browser-verified end to end, including a real TPEx OpenAPI call (389 real bonds).

Child tables (ChecklistStates, BrokerQuotes, TradeReviews) use DB-level `ON DELETE CASCADE` FK constraints instead of the Python version's manual cascade-delete-in-app-code approach.

**Bug fixed during this pass**: the initial C# importer unconditionally overwrote all Bond fields on every upsert, unlike Python's dict-based partial update (a CSV column absent from the file, or TPEx's 5-of-9-field response, never touches the existing DB value in Python). Fixed by adding `BondImportRow.PresentFields` (which canonical fields this row's source actually supplied) and making `BondService.UpsertRowsAsync` only assign present fields. Verified live: pre-set a bond's CB price/premium, ran a real TPEx update against it, confirmed those fields survived while TPEx-sourced fields (name/dates) updated.

See [[reference-blazor-server-gotchas]] for the three Blazor-specific bugs hit while building the login/download features (antiforgery+restart, enhanced-nav intercepting file downloads, and how to test Blazor apps with claude-in-chrome).

**Why:** user's own choice among presented options, framed as "先做核心 MVP" — full feature parity was explicitly declined for this pass.

**How to apply:** when resuming CBAS .NET work, port the deferred features from `backend/app/main.py` (FastAPI) as the spec/reference — it's the complete, working feature set. Don't re-derive requirements from the Obsidian product-design note alone; the Python code is more precise about exact field names and behavior. See also [[reference-mysql-local-dev-account]] and [[project-cbas-overview]] for the original product design context (read from Obsidian, not duplicated here).
