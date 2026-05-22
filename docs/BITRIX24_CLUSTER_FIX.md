# Bitrix24 Cluster Configuration Guide

## Problem: UNIQUE ID ERROR

### Symptoms
- `Permission denied: UNIQUE ID ERROR` in site_checker.php
- Multiple SERVERID cookies (web01, web02, web03) indicating load balancing
- check_localredirect, check_memory_limit, check_http_auth tests failing

### Root Cause
Requests are being load-balanced across multiple backend servers without sticky sessions.
Each server generates a different unique_id, causing Bitrix24's integrity check to fail.

## Solution

### Option 1: Use Fixed Nginx Configuration (Recommended)

1. **Backup current configuration:**
   ```bash
   sudo cp /etc/nginx/conf.d/99-proxy.conf /etc/nginx/conf.d/99-proxy.conf.backup
   ```

2. **Apply the fixed configuration:**
   ```bash
   sudo cp /root/99-proxy.conf.bitrix24_fixed /etc/nginx/conf.d/99-proxy.conf
   ```

3. **Test and reload Nginx:**
   ```bash
   sudo nginx -t && sudo systemctl reload nginx
   ```

### Option 2: Run Health Check Script

```bash
# Install sshpass if not available
sudo apt-get install -y sshpass

# Run the cluster health check
/root/bitrix24_cluster_check.sh
```

### Option 3: Manual Cluster Configuration

On each cluster node (10.0.1.220, 10.0.1.221, 10.0.1.222):

1. **Check Bitrix site ID consistency:**
   ```bash
   cat /etc/bitrix_site_id
   # Should be identical on all nodes
   ```

2. **Check Bitrix license key:**
   ```bash
   cat /var/www/*/bitrix/license_key.php
   # Should be identical on all nodes
   ```

3. **Check database configuration:**
   ```bash
   cat /var/www/*/bitrix/php_interface/dbconn.php
   # Database settings should be identical
   ```

4. **Verify shared cache configuration:**
   ```bash
   # Check memcached/redis settings in bitrix configuration
   grep -r "memcached\|redis" /var/www/*/bitrix/php_interface/
   ```

## Nginx Upstream Configuration

The fixed configuration includes:

```nginx
upstream bitrix24_cluster {
    ip_hash;  # Sticky sessions by client IP
    
    server 10.0.1.220:80 weight=1 max_fails=3 fail_timeout=30s;
    server 10.0.1.221:80 weight=1 max_fails=3 fail_timeout=30s;
    server 10.0.1.222:80 weight=1 max_fails=3 fail_timeout=30s;
    
    keepalive 32;
}
```

## Verification

After applying the fix, run the Bitrix24 site checker:

```bash
curl -k https://b24.ahprostory.ru/bitrix/admin/site_checker.php?unique_id=test
```

All tests should pass without UNIQUE ID errors.

## Additional Fixes Applied

1. **WebSocket support** for /bitrix/subws/ (Push&Pull)
2. **Increased timeouts** for admin scripts (900s)
3. **Proper buffering** for large file uploads (256M)
4. **Security headers** (X-Frame-Options, X-Content-Type-Options)
5. **Health check endpoint** at /health

## Files Created

- `/root/99-proxy.conf.bitrix24_fixed` - Fixed Nginx configuration
- `/root/bitrix24_cluster_check.sh` - Cluster health check script
- `/root/BITRIX24_CLUSTER_FIX.md` - This documentation

## SSH Credentials

- **Username:** vardo001
- **Password:** !P09710023p
- **Port:** 22
- **Nodes:** 10.0.1.220, 10.0.1.221, 10.0.1.222
