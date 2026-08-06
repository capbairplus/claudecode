---
name: reference-blazor-server-gotchas
description: "Three .NET 8 Blazor Web App (Blazor Server) gotchas hit building CBAS's login and file-download features"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9e4d4635-bf8e-4009-a62e-009fbc56772e
  modified: 2026-08-05T17:14:16.447Z
---

Hit while adding cookie auth + file downloads to a .NET 8 Blazor Web App (`--interactivity Server`) in [[project-cbas-dotnet-rewrite]]. General enough to apply to any future Blazor Server work, not just CBAS.

**1. Antiforgery tokens break on every `dotnet run` restart unless keys are persisted.**
ASP.NET Core's Data Protection system keeps its key ring in memory by default. Every process restart generates a new key, silently invalidating any antiforgery token embedded in an already-rendered page (e.g. a login form the browser still has open, or a cached HTML response). Symptom: "A valid antiforgery token was not provided with the request" on a form that worked fine before the last restart — easy to misdiagnose as a form-wiring bug when it's actually just key rotation.
**Fix**: `builder.Services.AddDataProtection().PersistKeysToFileSystem(new DirectoryInfo(...)).SetApplicationName(...)` — a few lines in `Program.cs`, keys survive restarts, done. Do this on any Blazor Server (or other ASP.NET Core antiforgery-using) app from the start, not just after hitting the bug.

**2. .NET 8's "enhanced navigation" silently swallows `<a>` clicks meant to trigger a real file download.**
Blazor Web Apps intercept same-origin `<a>` clicks by default and fetch the destination via JS to patch the DOM in place, instead of letting the browser do a normal navigation. This is transparent for links to other Razor pages, but for an endpoint that returns a binary file (e.g. `Results.File(...)` for a CSV/SQL download), the fetch-based interception means: no error, no console warning, the page just doesn't do anything — the download silently never happens.
**Fix**: add `data-enhance-nav="false"` to any `<a>` whose target is a file-download endpoint rather than another page.

**3. Testing Blazor Server downloads with claude-in-chrome: screenshots/clicks alone won't confirm success — use `read_network_requests`.**
A successful file-download response doesn't change the visible page (no navigation, no new DOM), so a screenshot proves nothing. `mcp__claude-in-chrome__read_network_requests` (call it once to start tracking, perform the click, call it again) is what actually shows whether the request fired and what status code came back. Also: this machine's Chrome profile has `"download":{"prompt_for_download": true}` in Preferences, meaning downloads normally show a native Save-As dialog automation can't drive — but CDP-automated clicks appear to bypass/auto-approve it in practice (no dialog window ever showed up in `EnumWindows`), so don't assume a real download failed just because the file isn't visible in `~/Downloads` — check the network status code first.

**How to apply**: when starting a new Blazor Server project or adding auth/downloads to an existing one, apply fixes #1 and #2 preemptively rather than waiting to hit them.
