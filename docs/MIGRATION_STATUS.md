# WIRE GUARD MIGRATION & PROXY TRANSFER REPORT
Date: Sunday, March 22, 2026

## 1. NETWORK TOPOLOGY
- **New Public Entry (45.139.185.45):** 
  - Tunnel IP: 10.10.10.1
  - Virtual Gateway IP: 10.0.1.111
  - Role: Nginx Proxy Manager, SSL Termination, Main Gateway for cluster.
- **Old Local Gateway (10.0.1.110):**
  - Tunnel IP: 10.10.10.2
  - Role: WireGuard Client, Proxy ARP provider for 10.0.1.111, NAT exit for local VMs.

## 2. COMPLETED TASKS
1. **WireGuard Tunnel:** Established 10.10.10.1 <-> 10.10.10.2.
2. **NPM Migration:** Successfully moved `/root/npm` data to the new server.
3. **Gateway Shift:** All cluster VMs (130, 131, 132, 133, 200, 201, 210, 221, 230, 50) now use 10.0.1.111 as default route.
4. **Configuration Audit:** Mass replace 10.0.1.110 -> 10.0.1.111 in /etc/ on all VMs.
5. **Real IP Fix:** Added 10.10.10.1 and 10.0.1.111 to trusted proxies on web servers.

## 3. VERIFIED DOMAINS
- b24.ahprostory.ru: OK (200)
- vks.ahprostory.ru: OK (200)
- stat.vks.ahprostory.ru: OK (200)
- npm.ahprostory.ru: OK (200)
- n8n.ahprostory.ru: OK (200)
- ai.ahprostory.ru: OK (405 - Backend alive)

## 4. PORT FORWARDING (New Server)
- TCP: 80, 443, 81, 4443, 5222, 5349, 3478, 8088, 8006, 8090
- UDP: 51820 (WG), 5349, 3478, 8893-8895, 10000-10001

## 5. CREDENTIALS SUMMARY
- SSH/OS: vardo001 / !P09710023p
- Redis: B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!
- NPM UI: (Previous credentials maintained)
