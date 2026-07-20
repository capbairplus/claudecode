---
name: vigor-network-troubleshooting
description: Use when inspecting or changing DrayTek Vigor settings, especially Vigor 2960 firewall rules, NAT/port redirection, IP/service objects, rule order, hit counters, syslog, SSH CLI, plink automation, source-IP restrictions, TCP/UDP reachability, VPN/VLAN routing, SQL Server exposure, or Wake-on-LAN.
---

# Vigor Network Troubleshooting

## Safety First

Treat router administration as live infrastructure work.

- Prefer read-only inspection until the user explicitly asks to change settings.
- Do not press Apply, Save, Delete, Reset, Reboot, Factory Default, or firmware actions unless the user clearly authorized that exact change.
- Do not run `restart`, `reboot`, service restarts such as `restart fpp`, or anything that may drop active sessions without asking first and naming the expected impact.
- Before recommending a change, state what it affects: NAT, firewall, service object, IP object, VPN route, VLAN, or host firewall.
- When using Chrome to inspect the UI, keep track of whether you are on the home router or company router. Verify by URL and visible page title before drawing conclusions.
- If a form is open, use Cancel/Escape to exit after inspection unless the user asked to apply.

## Core Workflow

Use this order for Vigor port, firewall, and reachability issues:

1. Identify the traffic path.
   - Source IP/subnet, destination WAN/LAN IP, protocol, port, and internal host.
   - Note whether the path is LAN-to-LAN VPN, local VLAN routing, or Internet-to-WAN NAT.

2. Check NAT/port redirection first for inbound WAN services.
   - Confirm the external port maps to the intended internal IP and port.
   - Confirm the NAT profile is enabled and tied to the correct WAN/IP alias.
   - If restricting by source IP, prefer the NAT/Open Ports source IP field when available; do not rely only on a later IP Filter rule until counters prove it is on the traffic path.

3. Check firewall rule order.
   - Find the allow rule for the service/source.
   - Confirm it is above broad deny rules such as WAN-to-LAN blocks.
   - Confirm the rule is enabled and uses the expected IN/OUT interfaces.

4. Check objects.
   - Service object: protocol and source/destination port ranges.
   - IP object/group: exact source IP/subnet and target IP when needed.
   - Avoid broad service ranges when one port is intended.

5. Verify with counters and logs.
   - Use hit/match count to determine whether the router saw the traffic.
   - Enable syslog temporarily for new or risky allow rules when useful.
   - Distinguish "rule did not match" from "matched but application failed."
   - Confirm protocol separately. VNC viewers or NAT entries may create UDP flows even when the expected test is TCP.
   - If a filter's match count stays at zero while `status conn` shows active flows, inspect NAT, fast path/FPP, rule interface (`all_wans` vs observed `dev=lan-lan1`), and whether traffic is bypassing that filter group.

6. Test from the right source.
   - `Test-NetConnection <host> -Port <port>` is preferred on Windows.
   - `telnet <host> <port>` only confirms TCP connection state; a blank cursor usually means connected for non-text services such as SQL Server.

## Vigor 2960 SSH CLI Notes

- From the user's workstation on the `192.168.3.x` network, direct SSH to the company Vigor can work when routing/firewall allows `192.168.3.31 -> 192.168.1.1`.
- Known successful local command from the user's PC:
  `ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa admin@192.168.1.1`
- If the Vigor SSH management port is changed from 22, use `ssh -p <port> ...`; never use `ssh 192.168.1.1:<port>`.
- Vigor 2960 SSH may require legacy RSA options from OpenSSH clients:
  `ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa admin@192.168.1.1`
- The CLI is interactive. After SSH login it may ask for `login:` and `Password:` again before the `Vigor2960>` prompt.
- Run `enable` before `uci`, `status conn`, `fpp`, `restart`, or `apply` commands that require privileged mode.
- `ssh 192.168.1.1:1688` is invalid syntax. Use `ssh -p 1688 admin@192.168.1.1`.
- Use `status conn <ip>` to confirm the router actually sees a source IP and protocol. Treat `conntrack` evidence as stronger than GUI expectation.
- `uci set ...`, `uci commit ...`, and `apply` write the UCI config layer, but do **not** reliably regenerate the underlying iptables/ipset enforcement — `uci get ...` echoing the new value back is NOT proof the change actually took effect. See the temp-IP warning below; treat any CLI-based config write as suspect until confirmed via Web UI or live traffic/syslog testing, not just a follow-up `uci get`.
- `uci export firewall` can be slow and verbose. Avoid interactive automation that redirects large stdout into an unread buffer; it may deadlock.
- When automating with PuTTY `plink.exe`, pass the cached host key explicitly in batch/server contexts. Never store router passwords in skill files or final answers.
- Redact passwords from captured output before showing or saving logs.

### Local PC to Vigor Firewall Workflow

Use this flow when operating directly from the user's PC, not through the Solis web host:

```text
ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa admin@192.168.1.1
```

Expected interactive sequence:

```text
admin@192.168.1.1's password:
login: admin
Password:
Vigor2960>
enable
Vigor2960#
```

Only run firewall/NAT commands after the prompt is `Vigor2960#`.

Common read checks:

```text
uci get ip_object.temp.start_ip
uci get firewall.NewWebServer.proto
uci get firewall.NewWebServer.src_ip_obj
uci get firewall.CapbairVNC5906.proto
uci get firewall.CapbairVNC5906.src_ip_obj
status conn <external-source-ip>
```

Common temp IP update (read-only diagnostic form — **do not use this to actually change the value**, see warning below):

```text
uci get ip_object.temp.start_ip
```

**⚠️ Known bug, confirmed 2026-07-11: do not update `ip_object.temp.start_ip` (or any IP object's value) via CLI `uci set`.**
`uci set ip_object.<name>.start_ip <new-ip>` + `uci commit` + `apply` writes the UCI config correctly — `uci get` will always echo the new value back — but the underlying iptables/ipset enforcement frequently never regenerates. Filter rules referencing that object keep matching stale/no data even though the config looks right. This was confirmed by side-by-side testing: a Web-UI-created object with an identical value worked; the CLI-updated `temp` object did not, and deleting+recreating `temp` via Web UI only "fixed" it because the next CLI test happened to reuse the same value — a genuinely different value written via CLI to the freshly-recreated object failed again.

**The only reliable way to change `ip_object.temp.start_ip` (or similar) is to submit the change through the router's own Web UI form.** `changetempip.php` on the Solis web host (`C:\wordpresstemp\changetempip.php`, public URL `https://www.solistex.com/changetempip.php`, behind HTTP Basic Auth) was rewritten to drive a headless Chrome browser via Selenium (`C:\wordpresstemp\selenium\update-temp-ip.ps1`) that logs into the Web UI and edits the IP object through the real form — this is the only path proven to propagate to enforcement. Full implementation notes (SmartClient XPath-by-text selectors, PowerShell 4.0 gotchas, UTF-8 BOM requirement, Big5-vs-UTF-8 pipe encoding fix) are in `VIGOR2960-SSH-CLI-GUIDE.md` chapter 9. If you need to change this value programmatically, reuse/extend that Selenium script — do not fall back to CLI `uci set` for it.

## Solis Vigor 2960 Site Facts

Treat these as site-specific hints to verify before changing:

- Vigor LAN IP: `192.168.1.1`.
- Solis WordPress/web host: `192.168.1.33`.
- Public web IP alias used by the WordPress site: `59.124.11.219`.
- Public service IP observed for VNC/SQL tests: `59.124.11.218`.
- Common source IP object for the owner: `CapbairIP = 122.116.82.127`.
- Temporary source IP object used by the web tool: `temp`.
- Web host plink path used in prior automation: `C:\wordpresstemp\plink.exe`.
- Known Vigor host key fingerprint: `ssh-rsa 2048 SHA256:GXBA40fQAhKJaQJ261pMgXrlr6i/UKVPBRz8OIIhSkQ`.

## References

Read only the relevant reference:

- For Vigor 2960 UI paths and rule checklist, read `references/vigor-2960-checklists.md`.
- For SQL Server 1433 or other restricted port forwarding, read `references/sql-port-forwarding.md`.
- For Wake-on-LAN over VLAN, VPN, or WAN, read `references/wol-cross-subnet.md`.
- For the full CLI-write-doesn't-enforce bug writeup and the Selenium/Web-UI automation approach for `changetempip.php`, read chapter 9 of `G:\codex2\vigor2960\VIGOR2960-SSH-CLI-GUIDE.md` before touching that tool.
