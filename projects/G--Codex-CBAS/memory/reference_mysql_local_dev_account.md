---
name: reference-mysql-local-dev-account
description: "Local MySQL server exists and has a usable full-access dev account; credentials live in Obsidian, not here"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9e4d4635-bf8e-4009-a62e-009fbc56772e
  modified: 2026-08-05T13:16:20.599Z
---

This machine already has MySQL Server 8.4 running as a Windows service (`MySQL`, port 3306, client at `C:\mysql\bin\mysql.exe`). There is an existing account (originally set up for WordPress sites) that already has effectively full privileges on `*.*` (SELECT/INSERT/UPDATE/DELETE/CREATE/DROP/ALTER/etc.) but **not** `GRANT OPTION` — so `CREATE USER` + `GRANT ... TO otheruser` from this account fails with `ERROR 1044 Access denied ... to database`, even though the account can directly read/write/create-tables-in any database including a brand new one.

**Why this matters:** don't waste time trying to provision a fresh scoped MySQL user for a new local app (e.g. `cbas_user`) — it'll hit the GRANT OPTION wall. Just connect the app directly with the existing full-access account and create/migrate the target database directly; no separate grant step needed.

**How to apply:** full connection details (username/password) are documented in the Obsidian vault at `WordPress/MySQL 資料庫與帳號.md` — read that note when a project needs a local MySQL connection string, rather than asking the user or trying to create new credentials from scratch. Used for [[project-cbas-dotnet-rewrite]]'s `ConnectionStrings:CbasDb`.
