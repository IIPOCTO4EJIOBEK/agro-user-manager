# Call Center — Production Deployment

## Server: 10.1.17.124 (FusionPBX / FreeSWITCH)

## Architecture

```
Browser (WSS :443/fsws) → Nginx → localhost:9090 (FreeSWITCH ESL WebSocket)
Browser (HTTPS :443)     → Nginx → /var/www/call-center/ (operator/admin/manager.html)
Browser (REST API)       → Nginx → /api/ → localhost:3000 (Node.js server.js)
Browser (WebSocket)      → Nginx → /ws → localhost:8080 (Node.js WS)
SD Plus telephony        → ami-bridge :5038 (AMI protocol) → FreeSWITCH ESL :8021
CDR data                 → cdr-collector → PostgreSQL (fusionpbx DB)
```

## Services

| Service | Port | Status | Type |
|---------|------|--------|------|
| freeswitch | 8021 (ESL), 9090 (WS) | running | Core PBX |
| nginx | 443 (SSL) | running | Reverse proxy |
| server.js | 3000 (REST), 8080 (WS) | running | Node.js backend |
| ami-bridge | 5038 | running | SD Plus AMI |
| ws-proxy | 9091 | running | WS proxy |
| cdr-collector | - | running | CDR → PostgreSQL |
| xml_cdr | - | running | FusionPBX CDR |

## Frontend

- /var/www/call-center/operator.html — Operator panel with WebRTC/SIP.js
- /var/www/call-center/admin.html — Admin panel
- /var/www/call-center/manager.html — Manager dashboard

## Quick Start (Restore)

```bash
sudo systemctl start freeswitch nginx
cd /opt/call-center && nohup node server.js &
sudo systemctl start ami-bridge ws-proxy cdr-collector xml_cdr
```
