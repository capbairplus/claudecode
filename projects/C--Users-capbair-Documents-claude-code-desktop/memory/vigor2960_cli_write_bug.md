---
name: vigor2960-cli-write-bug
description: Vigor 2960 CLI (uci set) writes to IP objects update the config value but never regenerate the underlying iptables/ipset — only Web UI edits reliably take effect. Fixed changetempip.php with Selenium browser automation.
metadata: 
  node_type: memory
  type: project
  originSessionId: 9d78ef7b-8dc1-4e1f-8b53-94271739de82
---

On the Solis site's DrayTek Vigor 2960 router (192.168.1.1, admin CLI via SSH port 1688), writing a new value to an existing IP object via CLI (`uci set ip_object.<name>.start_ip <ip>; uci commit ip_object; apply`) correctly updates the UCI config — `uci get` always reflects the new value — but the underlying iptables/ipset enforcement is frequently never regenerated, so IP Filter rules referencing that object silently keep matching stale (or no) data. This is the same root cause documented earlier for CLI-created filter rules, but it also applies to editing the *value* of an existing IP object, including one that was originally created via Web UI.

**Why:** Confirmed by side-by-side testing: a Web-UI-created object with an identical value works in filter rules; the same value written via CLI to the router's long-standing "temp" object (used for dynamic remote-IP allowlisting) did not enforce, even after deleting and recreating the object via Web UI as a workaround — a follow-up CLI update to that freshly-recreated object failed again once a genuinely new value was set. So the only thing that reliably works is submitting the change through the Web UI's own form.

**How to apply:** For any Vigor 2960 config change on this router that must actually take effect immediately (not just read-only queries), do not rely on CLI/SSH writes — drive the real Web UI instead. The site's `changetempip.php` (deployed at `C:\wordpresstemp\changetempip.php` on the Solis webserver 192.168.1.33, public URL `https://www.solistex.com/changetempip.php`, now behind HTTP Basic Auth) was rewritten to use Selenium + headless Chrome (`C:\wordpresstemp\selenium\update-temp-ip.ps1`) to log into the router's Web UI and edit the IP object through the real form, since that is the only path proven to propagate correctly. Full details, including SmartClient UI quirks (XPath-by-text selectors, PowerShell 4.0 `::new()` incompatibility, UTF-8 BOM requirements, and the Big5-vs-UTF-8 pipe encoding issue for PowerShell→PHP output) are written up in [[vigor2960-ssh-cli-guide]] chapter 9 (`G:\codex2\vigor2960\VIGOR2960-SSH-CLI-GUIDE.md`) — read that before touching this router's automation again.
