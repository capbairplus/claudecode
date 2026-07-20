# Vigor 2960 Checklists

## Common UI Paths

- Firewall rules: `Firewall > Filter Setup > IP Filter`
- NAT forwarding: `NAT > Port Redirection`
- IP objects: `Object Setting > IP Object`
- IP groups: `Object Setting > IP Group`
- Service objects: `Object Setting > Service Type Object`
- Service groups: `Object Setting > Service Type Group`
- WOL: often `Applications > Wake on LAN`
- IP/MAC binding: often `LAN > Bind IP to MAC`
- Packet counters: `Firewall > Filter Packet Count` or counters inside IP Filter rules

Menu names may appear localized, for example:

- `防火牆 > 過濾器設定 > IP 過濾器`
- `NAT > 通訊埠重導向`
- `物件設定 > IP 物件`
- `物件設定 > 服務類型物件`

## Firewall Rule Review

For each relevant rule, capture:

- Rule/profile name.
- Enabled state.
- Action: allow or block.
- Syslog state.
- Input and output interface, such as `ALL WANS` and `ALL LANS`.
- Service object or service group.
- Source IP object/group.
- Destination IP object/group.
- Match/hit count.
- Rule order relative to broad block rules.

Interpretation rules:

- Empty source object usually means "any source."
- Empty destination object usually means "any destination."
- Empty service object usually means "any service."
- Allow rules below a matching block rule will not be reached.
- A hit count of zero after testing usually means source IP, port, WAN IP, interface, NAT, or rule order is wrong.
- If a user reports a successful connection but the intended allow rule still shows zero hits, do not keep tuning that rule blindly. Check `status conn <source-ip>` on the router to see the real protocol, public destination, internal translated host, and observed device/interface.
- A Vigor conntrack line may show UDP for VNC-related traffic even when the planned restriction was TCP. Check both TCP and UDP NAT/service settings.
- If NAT rules show `proto tcp` and source restrictions but an existing UDP flow remains `[ASSURED]`, suspect stale conntrack/FPP runtime state. Ask before running `restart fpp` because it may interrupt active sessions.

## Safe Browser Practice

- Read the visible table and, when needed, open Edit only to inspect selected checkboxes and object details.
- Do not apply changes from an Edit dialog unless the user explicitly asked for that exact change.
- If a modal remains open after inspection, use Cancel or Escape and verify no settings were applied.
- Keep a short running note of which router is being inspected when both home and company Vigor UIs are open.

## Solis Vigor 2960 Known Firewall/NAT Restore Notes

These notes capture the live Vigor 2960 settings observed during the 2026-07-07 recovery after the `AllowVPN2LAN` group was accidentally deleted. Treat these as site-specific hints, then verify on the router screen before applying changes.

### IP Filter Groups

Known top-level IP filter groups:

- `Allown5905VNC`
- `NoWAN2LAN`
- `OnlyMyIP`

The current reconstructed WAN-to-LAN rules were placed inside the `NoWAN2LAN` group. Earlier screenshots showed a group named `AllowVPN2LAN`; if only `NoWAN2LAN` exists, continue using the visible group and verify rule order.

### `NoWAN2LAN` Group Rule Order

Keep allow rules above the final block rule:

1. `VPN2LAN` - allow
2. `AllowWebHTTPS` - allow web server HTTP/HTTPS
3. `NoWAN2LAN` - block catch-all WAN-to-LAN

If SQL access is needed, insert `TelnetSQL1433` above `NoWAN2LAN` as well.

### `AllowWebHTTPS` Rule

Observed live setting:

- Rule name: `AllowWebHTTPS`
- Enabled: true
- Action: allow
- Syslog: enabled
- Input interface: `ALL WANS`
- Output interface: `ALL LANS`
- Service objects: `HTTP` and `HTTPS`
  - `HTTP`: TCP source ports `1-65535`, destination port `80`
  - `HTTPS`: TCP source ports `1-65535`, destination port `443`
- Source IP objects: none selected, meaning any external source IP.
- Destination/target IP object: `WebserverIP`
- Rule position: above the `NoWAN2LAN` block rule.
- Observed hit/match count after setup: `30`.

Interpretation:

- This opens both `http://` and `https://` to the web server.
- If only HTTPS should be exposed, uncheck `HTTP` and leave only `HTTPS`.
- If HTTP-to-HTTPS redirect is expected, keeping both `HTTP` and `HTTPS` is acceptable.

### `NoWAN2LAN` Block Rule

Use this as the final catch-all block rule in the WAN-to-LAN group:

- Rule name: `NoWAN2LAN`
- Enabled: true
- Action: block
- Syslog: enabled
- Input interface: `ALL WANS`
- Output interface: `ALL LANS`
- Service/source/destination objects: leave unselected unless a later screenshot proves otherwise.
- Must be the last rule in the group.
- Observed hit/match count after setup: `1600`.

### `VPN2LAN` Rule

Observed list-level setting:

- Rule name: `VPN2LAN`
- Enabled: true
- Action: allow
- Syslog: enabled
- Input/output list field showed `[IN] all_wans,[OUT] all_...`.
- Target fields showed LAN objects including `LAN01IP` and `LAN02IP` at list level; open the rule before editing because the full object selection was not captured in detail.
- Observed hit/match count after setup: `13`.

### Port Redirection Observed Earlier

Relevant NAT entries seen in the Vigor 2960 `NAT > Port Redirection` table:

- `Webserver`: enabled, WAN `wan1`, IP alias beginning `59.124.11.219...`, external ports `80,5933` to `192.168.1.33`, internal ports `80,5933`.
- `WebserverHT...`: enabled, WAN `wan1`, IP alias beginning `59.124.11.219...`, external port `443` to `192.168.1.33`, internal port `443`.
- `SQLSGPOS`: enabled, WAN `All`, external ports `1433,5906` to `192.168.1.6`, internal ports `1433,5906`.
- `VncSGPublic`: enabled, WAN `wan1`, IP alias beginning `59.124.11.220...`, external ports `5905,80,443` to `192.168.1.5`, internal ports `5905,80,443`.

When troubleshooting public access, check NAT first, then confirm the matching firewall allow rule is above `NoWAN2LAN`.

### Solis 5906/5907 Source Restriction Notes

Observed objective: allow only `CapbairIP` (`122.116.82.127`) to reach `59.124.11.218:5906` and `59.124.11.218:5907`.

Known NAT state from the troubleshooting session:

- `CapbairVNC5906`: public `5906` -> `192.168.1.6:5906`, source IP object `CapbairIP`, protocol `tcp`.
- `NewWebServer`: public `5907` -> `192.168.1.7:5907`, source IP object `CapbairIP`, protocol `tcp`.
- Old `SQLSGPOS` was disabled but still had historical `more_1to1_port` data; verify status before drawing conclusions.

Useful CLI checks:

```text
enable
uci get firewall.NewWebServer.proto
uci get firewall.NewWebServer.src_ip_obj
uci get firewall.CapbairVNC5906.proto
uci get firewall.CapbairVNC5906.src_ip_obj
status conn <external-test-ip>
```

If unauthorized external IPs still connect:

- First check whether the flow is TCP or UDP in `status conn`.
- Check whether the destination is really `59.124.11.218` and translated host is `192.168.1.6` or `192.168.1.7`.
- Check whether GUI rule counters move. A zero counter means the traffic is not matching that IP Filter rule.
- If a stale UDP flow survives after config changes, ask before `restart fpp`; do not restart it silently.
