---
name: obsidian-mcp-integration
description: "Obsidian vault is connected to Claude Code via the Local REST API plugin's built-in MCP server"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 152ee7cb-76d0-416f-a5c6-fdfe99d27ac8
---

Claude Code is registered (user scope, in `C:\Users\capbair\.claude.json`) to talk to the user's Obsidian vault via an MCP server named `obsidian`.

- Setup: Obsidian community plugin **"Local REST API"** (coddingtonbear) — as of the Q2 2026 update it ships its own MCP endpoint, no separate MCP server package needed.
- Endpoint: `https://127.0.0.1:27124/mcp/`, auth via `Authorization: Bearer <token>` header (token generated in the plugin's settings page inside Obsidian).
- Registered with: `claude.cmd mcp add obsidian --transport http https://127.0.0.1:27124/mcp/ --header "Authorization: Bearer <token>" --scope user`
- Requires Obsidian.app to be running (the REST server lives inside the Obsidian plugin process, not a standalone service).
- Available MCP tools once connected: list_files_in_vault, list_files_in_dir, get_file_contents, search, append_content, patch_content (insert relative to headings/blocks), delete_file.
- A new Claude Code session must be started after registration for the MCP tools to appear — existing sessions don't hot-reload newly added MCP servers.

See also [[powershell_npm_ps1_execution_policy]] for the Windows-specific hurdle hit while running `claude mcp add`.

**Working setup confirmed 2026-07-13:** `claude mcp list` initially showed "Failed to connect" on the HTTPS endpoint — cause was the plugin's self-signed cert not being trusted by the OS. This user's plugin instance has the non-encrypted HTTP (27123) endpoint disabled/crossed-out in its own settings UI, so the HTTP-port workaround wasn't an option here — fixed instead by downloading the cert from the Obsidian plugin settings page (link next to "Encrypted (HTTPS) API URL") and installing it into Windows' Local Machine → Trusted Root Certification Authorities store, then `claude mcp remove obsidian` + re-`add` with the same `https://127.0.0.1:27124/mcp/` URL. Status went to "Connected" after that.
