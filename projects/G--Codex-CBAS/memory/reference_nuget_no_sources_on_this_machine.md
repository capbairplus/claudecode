---
name: reference-nuget-no-sources-on-this-machine
description: "This machine's global NuGet.Config has zero package sources configured — dotnet add package fails with \"no version available\" until nuget.org is added"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9e4d4635-bf8e-4009-a62e-009fbc56772e
  modified: 2026-08-05T13:16:27.931Z
---

`dotnet nuget list source` on this machine returns empty — the user-level `NuGet.Config` (`C:\Users\capbair\AppData\Roaming\NuGet\NuGet.Config`) has an empty `<packageSources>` block. Any `dotnet add package X` fails with a misleading error (`套件 'X' 沒有可用的版本` / "no version available for X"), which looks like a version-pinning problem but is actually "no source configured at all."

**Why this matters:** don't chase version numbers or compatibility theories when `dotnet add package` fails with "no available version" — check `dotnet nuget list source` first.

**How to apply:** fix with `dotnet nuget add source https://api.nuget.org/v3/index.json -n nuget.org` (one-time, machine-wide) before any `dotnet add package` on a fresh project on this machine. Already done as of 2026-08-05 during [[project-cbas-dotnet-rewrite]], so future .NET package installs should work without re-adding it — but if it resurfaces empty, this is why.
