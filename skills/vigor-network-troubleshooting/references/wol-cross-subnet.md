# Wake-on-LAN Across Subnets

## Key Principle

Ping between subnets proves unicast routing. It does not prove Wake-on-LAN will work.

WOL magic packets typically need to be delivered as a layer-2 broadcast inside the target host's VLAN/broadcast domain. Routers commonly do not forward broadcast traffic between VLANs, VPNs, or WAN and LAN.

## Diagnostic Order

1. Confirm same-VLAN WOL works first.
   - From a host in the target subnet, send to the subnet broadcast address, such as `192.168.1.255:9`.
   - If this fails, fix BIOS/UEFI, NIC power management, Windows Fast Startup, switch, or host power state before router work.

2. For cross-VLAN or LAN-to-LAN VPN WOL, identify the target broadcast domain.
   - Example: source `192.168.3.0/24`, target `192.168.1.161`, target broadcast `192.168.1.255`.

3. Check whether the target-side Vigor can send WOL itself.
   - Prefer built-in Vigor Wake on LAN when available.
   - Bind IP to MAC if the UI supports it: `192.168.1.161` -> target MAC.

4. If trying router relay, look for:
   - Directed broadcast.
   - UDP broadcast relay.
   - UDP helper.
   - Wake on WAN.
   - Firewall rules allowing UDP 7 or 9 from the trusted source.

5. If router relay is unsupported, use a relay host.
   - A NAS, Windows host, Linux host, Proxmox server, or small always-on device inside the target VLAN sends the local broadcast.
   - Access the relay through VPN or a tightly restricted management path.

## PowerShell Magic Packet

Replace the MAC address and target broadcast:

```powershell
$mac = "10-FF-E0-22-AE-6B"
$bytes = ($mac -split "[:-]" | ForEach-Object { [Convert]::ToByte($_,16) })
$packet = [byte[]](,0xFF * 6 + ($bytes * 16))
$udp = New-Object System.Net.Sockets.UdpClient
$udp.EnableBroadcast = $true
$udp.Connect("192.168.1.255", 9)
[void]$udp.Send($packet, $packet.Length)
$udp.Close()
"Sent WOL packet for $mac"
```

This command does not receive an acknowledgement. No output from the target is normal.

## Security Guidance

- Avoid exposing UDP 9 broadly from the Internet to a LAN broadcast address.
- Prefer VPN plus Vigor built-in WOL or an internal relay.
- If using Wake on WAN, restrict source IPs and document the exposed UDP port.
