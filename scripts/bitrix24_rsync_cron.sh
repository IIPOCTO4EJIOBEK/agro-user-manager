#!/bin/bash
# ============================================================================
# BITRIX24 CLUSTER - RSYNC СИНХРОНИЗАЦИЯ (CRON)
# ============================================================================

SLAVE_NODES=("10.0.1.221" "10.0.1.222")
SSH_USER="root"
SSH_PASS="!P09710023p"
SSH_PORT="22"
LOG_FILE="/var/log/bitrix24_rsync_sync.log"

SYNC_FILES=(
    "/etc/php-fpm.d/www.conf"
    "/etc/httpd/conf.d/php.conf"
    "/home/bitrix/www/bitrix/license_key.php"
    "/home/bitrix/www/bitrix/.settings.php"
    "/home/bitrix/www/bitrix/.settings_extra.php"
    "/home/bitrix/www/bitrix/php_interface/dbconn.php"
    "/home/bitrix/www/auth/.htaccess"
)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

sync_file() {
    local file=$1
    local node=$2
    
    if [ ! -f "$file" ]; then
        log "  ⚠ Файл $file не существует локально"
        return 1
    fi
    
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" \
        "$SSH_USER@$node" "cp -p $file ${file}.bak.auto 2>/dev/null" || true
    
    sshpass -p "$SSH_PASS" rsync -avz -e "ssh -p $SSH_PORT -o StrictHostKeyChecking=no" \
        "$file" "$SSH_USER@$node:$file" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        log "  ✓ $file синхронизирован на $node"
        return 0
    else
        log "  ✗ Ошибка синхронизации $file на $node"
        return 1
    fi
}

main() {
    log "=== Начало синхронизации ==="
    
    for node in "${SLAVE_NODES[@]}"; do
        log "Синхронизация на узел: $node"
        
        for file in "${SYNC_FILES[@]}"; do
            sync_file "$file" "$node"
        done
        
        log "Перезапуск служб на $node"
        sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" \
            "$SSH_USER@$node" "systemctl reload php-fpm 2>/dev/null; systemctl reload httpd 2>/dev/null" >> "$LOG_FILE" 2>&1 || true
    done
    
    log "=== Синхронизация завершена ==="
}

main
