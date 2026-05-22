#!/bin/bash
# ============================================================================
# BITRIX24 CLUSTER HEALTH CHECK SCRIPT
# Cluster Nodes: 10.0.1.220, 10.0.1.221, 10.0.1.222
# SSH Port: 22, Credentials: vardo001 / !P09710023p
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cluster Configuration
CLUSTER_NODES=("10.0.1.220" "10.0.1.221" "10.0.1.222")
SSH_USER="vardo001"
SSH_PASS="!P09710023p"
SSH_PORT="22"
BITRIX_DOMAIN="b24.ahprostory.ru"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  BITRIX24 CLUSTER HEALTH CHECK${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# ----------------------------------------------------------------------------
# Function: Check SSH connectivity
# ----------------------------------------------------------------------------
check_ssh() {
    local node=$1
    echo -e "${YELLOW}[SSH] Checking $node...${NC}"
    
    if sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$SSH_PORT" "$SSH_USER@$node" "echo 'OK'" 2>/dev/null; then
        echo -e "${GREEN}  ✓ SSH connection successful${NC}"
        return 0
    else
        echo -e "${RED}  ✗ SSH connection failed${NC}"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Function: Check Nginx configuration
# ----------------------------------------------------------------------------
check_nginx_config() {
    local node=$1
    echo -e "${YELLOW}[NGINX] Checking configuration on $node...${NC}"
    
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "sudo nginx -t 2>&1" 2>/dev/null || echo -e "${RED}  Failed to check nginx config${NC}"
}

# ----------------------------------------------------------------------------
# Function: Check Bitrix24 site_checker.php
# ----------------------------------------------------------------------------
check_bitrix_health() {
    local node=$1
    echo -e "${YELLOW}[BITRIX] Checking site_checker.php on $node...${NC}"
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" "https://$BITRIX_DOMAIN/bitrix/admin/site_checker.php?unique_id=test" 2>/dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}  ✓ Bitrix24 responding (HTTP $response)${NC}"
    else
        echo -e "${RED}  ✗ Bitrix24 not responding properly (HTTP $response)${NC}"
    fi
}

# ----------------------------------------------------------------------------
# Function: Check Nginx upstream configuration
# ----------------------------------------------------------------------------
check_upstream_config() {
    local node=$1
    echo -e "${YELLOW}[UPSTREAM] Checking upstream config on $node...${NC}"
    
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "grep -r 'upstream.*bitrix' /etc/nginx/ 2>/dev/null | head -20" || echo "  No upstream config found"
}

# ----------------------------------------------------------------------------
# Function: Check Bitrix cluster configuration
# ----------------------------------------------------------------------------
check_bitrix_cluster_config() {
    local node=$1
    echo -e "${YELLOW}[BITRIX CLUSTER] Checking cluster config on $node...${NC}"
    
    # Check for cluster configuration files
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "find /var/www -name 'cluster.php' -o -name 'bitrix_cluster.php' 2>/dev/null | head -10" || echo "  No cluster config found"
    
    # Check bitrix setup
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "ls -la /var/www/*/bitrix/modules/main/include/ 2>/dev/null | head -5" || echo "  Cannot access bitrix modules"
}

# ----------------------------------------------------------------------------
# Function: Synchronize Nginx configs across cluster
# ----------------------------------------------------------------------------
sync_nginx_configs() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}  SYNCHRONIZING NGINX CONFIGS ACROSS CLUSTER${NC}"
    echo -e "${BLUE}============================================================${NC}"
    
    local source_node="${CLUSTER_NODES[0]}"
    local config_file="/etc/nginx/conf.d/99-proxy.conf"
    
    echo -e "${YELLOW}Source node: $source_node${NC}"
    echo -e "${YELLOW}Config file: $config_file${NC}"
    echo ""
    
    for node in "${CLUSTER_NODES[@]}"; do
        if [ "$node" != "$source_node" ]; then
            echo -e "${YELLOW}[SYNC] Copying config to $node...${NC}"
            sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no -P "$SSH_PORT" \
                "$SSH_USER@$source_node:$config_file" \
                "$SSH_USER@$node:/tmp/99-proxy.conf.tmp" 2>/dev/null && \
            sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
                "sudo mv /tmp/99-proxy.conf.tmp $config_file && sudo nginx -t && sudo systemctl reload nginx" && \
            echo -e "${GREEN}  ✓ Config synchronized${NC}" || \
            echo -e "${RED}  ✗ Sync failed${NC}"
        fi
    done
}

# ----------------------------------------------------------------------------
# Function: Check logs for UNIQUE ID errors
# ----------------------------------------------------------------------------
check_unique_id_errors() {
    local node=$1
    echo -e "${YELLOW}[LOGS] Checking for UNIQUE ID errors on $node...${NC}"
    
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "grep -i 'unique.*id.*error' /var/log/nginx/*.log 2>/dev/null | tail -10" || echo "  No UNIQUE ID errors in nginx logs"
    
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "grep -i 'unique.*id' /var/www/*/bitrix/modules/main/admin/site_checker.php 2>/dev/null | head -5" || echo "  Checking bitrix files..."
}

# ----------------------------------------------------------------------------
# Function: Check server IDs consistency
# ----------------------------------------------------------------------------
check_server_ids() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}  CHECKING SERVER IDs ACROSS CLUSTER${NC}"
    echo -e "${BLUE}============================================================${NC}"
    
    for node in "${CLUSTER_NODES[@]}"; do
        echo -e "${YELLOW}[SERVER ID] $node:${NC}"
        sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
            "hostname; cat /etc/bitrix_site_id 2>/dev/null || echo 'No site_id file'" || echo "  Cannot connect"
        echo ""
    done
}

# ----------------------------------------------------------------------------
# MAIN EXECUTION
# ----------------------------------------------------------------------------

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  STEP 1: SSH CONNECTIVITY CHECK${NC}"
echo -e "${BLUE}============================================================${NC}"
for node in "${CLUSTER_NODES[@]}"; do
    check_ssh "$node"
done
echo ""

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  STEP 2: NGINX CONFIGURATION CHECK${NC}"
echo -e "${BLUE}============================================================${NC}"
for node in "${CLUSTER_NODES[@]}"; do
    check_nginx_config "$node"
done
echo ""

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  STEP 3: UPSTREAM CONFIGURATION CHECK${NC}"
echo -e "${BLUE}============================================================${NC}"
for node in "${CLUSTER_NODES[@]}"; do
    check_upstream_config "$node"
done
echo ""

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  STEP 4: BITRIX24 HEALTH CHECK${NC}"
echo -e "${BLUE}============================================================${NC}"
check_bitrix_health "${CLUSTER_NODES[0]}"
echo ""

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  STEP 5: UNIQUE ID ERROR LOG CHECK${NC}"
echo -e "${BLUE}============================================================${NC}"
for node in "${CLUSTER_NODES[@]}"; do
    check_unique_id_errors "$node"
done
echo ""

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  STEP 6: SERVER ID CONSISTENCY CHECK${NC}"
echo -e "${BLUE}============================================================${NC}"
check_server_ids
echo ""

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  RECOMMENDATIONS:${NC}"
echo -e "${BLUE}============================================================${NC}"
echo -e "${YELLOW}1.${NC} Ensure all cluster nodes have synchronized bitrix configuration"
echo -e "${YELLOW}2.${NC} Verify /etc/bitrix_site_id is identical on all nodes"
echo -e "${YELLOW}3.${NC} Check that LICENSE_KEY is the same across all nodes"
echo -e "${YELLOW}4.${NC} Ensure cache and session storage are shared (memcached/redis)"
echo -e "${YELLOW}5.${NC} Verify database connection settings are identical"
echo -e "${YELLOW}6.${NC} Use the fixed config: /root/99-proxy.conf.bitrix24_fixed"
echo ""
echo -e "${GREEN}Done!${NC}"
