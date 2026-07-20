# SQL Port Forwarding

## Goal

Allow a specific external source IP to reach a SQL Server TCP port through Vigor, without exposing the port to the entire Internet.

## Checklist

1. NAT/Port Redirection
   - Enabled.
   - Correct WAN profile or IP alias.
   - External port maps to the intended internal SQL host and internal port.
   - Example: WAN `1433` -> `192.168.1.6:1433`.

2. Service object
   - Protocol: TCP.
   - Source port: `1-65535`.
   - Destination port: the SQL port, commonly `1433-1433`.
   - Do not set destination `1433-65535` when only 1433 is intended.

3. Source IP object
   - Use a single IP object for one allowed external IP.
   - Use a range or group only when the business requirement needs multiple sources.

4. Firewall rule
   - Enabled.
   - Action: allow.
   - Input: WAN side, often `ALL WANS`.
   - Output: LAN side, often `ALL LANS`.
   - Service: SQL service object.
   - Source: allowed source IP object.
   - Destination: internal SQL host IP object when possible.
   - Place above broad WAN-to-LAN block rules.

5. Verification
   - Enable syslog temporarily for the allow rule if useful.
   - Ask the user to test from the allowed source.
   - Check hit count after the test.
   - If hit count increases but SQL login fails, the network path works and the issue is SQL authentication, SQL configuration, or host firewall.
   - If hit count remains zero, check source public IP, WAN IP/alias, NAT profile, service object, and rule order.

## Windows Test Commands

Use:

```powershell
Test-NetConnection 59.124.11.218 -Port 1433
```

`TcpTestSucceeded : True` means TCP reached a listener. It does not prove SQL credentials or database permissions.

Telnet can also test TCP:

```cmd
telnet 59.124.11.218 1433
```

A blank cursor commonly means connected for SQL Server because SQL Server is not a text banner service.
