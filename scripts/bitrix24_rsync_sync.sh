#!/bin/bash
# ============================================================================
# BITRIX24 CLUSTER - RSYNC СИНХРОНИЗАЦИЯ ВЕБ-УЗЛОВ
# Автоматическая синхронизация конфигурационных файлов между серверами
# ============================================================================

set -e

# Конфигурация
MASTER_NODE="10.0.1.220"  # Главный сервер (источник)
SLAVE_NODES=("10.0.1.221" "10.0.1.222")  # Подчиненные серверы
SSH_USER="root"
SSH_PASS="!P09710023p"
SSH_PORT="22"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Файлы для синхронизации
SYNC_FILES=(
    "/etc/php-fpm.d/www.conf"
    "/etc/httpd/conf.d/php.conf"
    "/home/bitrix/www/bitrix/license_key.php"
    "/home/bitrix/www/bitrix/.settings.php"
    "/home/bitrix/www/bitrix/.settings_extra.php"
    "/home/bitrix/www/bitrix/php_interface/dbconn.php"
    "/etc/httpd/conf.d/z_bx_custom_mpm.conf"
    "/etc/httpd/conf.d/z_unique_id.conf"
)

# Исключения для rsync
RSYNC_EXCLUDES=(
    "*.log"
    "*.bak.*"
    "*.tmp"
    "*.swp"
)

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  BITRIX24 CLUSTER - RSYNC СИНХРОНИЗАЦИЯ${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "${YELLOW}Главный сервер (источник):${NC} $MASTER_NODE"
echo -e "${YELLOW}Подчиненные серверы:${NC} ${SLAVE_NODES[*]}"
echo ""

# Функция для создания резервной копии на удаленном сервере
backup_remote() {
    local node=$1
    local file=$2
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "cp -p $file ${file}.bak.$timestamp 2>/dev/null || true"
}

# Функция для синхронизации файла через rsync
sync_file() {
    local source=$1
    local dest=$2
    local node=$3
    
    # Формирование строки исключений
    local excludes=""
    for exc in "${RSYNC_EXCLUDES[@]}"; do
        excludes="$excludes --exclude='$exc'"
    done
    
    # Синхронизация
    sshpass -p "$SSH_PASS" rsync -avz -e "ssh -p $SSH_PORT -o StrictHostKeyChecking=no" \
        $excludes "$source" "$SSH_USER@$node:$dest" 2>/dev/null
}

# Синхронизация на каждый подчиненный сервер
for node in "${SLAVE_NODES[@]}"; do
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Синхронизация на узел: $node${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    for file in "${SYNC_FILES[@]}"; do
        echo -e "${YELLOW}[ФАЙЛ] $file${NC}"
        
        # Проверка существования файла на мастере
        if sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$MASTER_NODE" \
            "test -f $file && echo 'exists' || echo 'not_exists'" 2>/dev/null | grep -q 'exists'; then
            
            # Создание резервной копии на целевом сервере
            echo -e "  ${YELLOW}→ Создание резервной копии...${NC}"
            backup_remote "$node" "$file"
            
            # Синхронизация файла
            echo -e "  ${GREEN}→ Синхронизация...${NC}"
            sync_file "$MASTER_NODE:$file" "$file" "$node"
            
            # Установка правильных прав
            echo -e "  ${YELLOW}→ Установка прав...${NC}"
            sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
                "chown --reference=$MASTER_NODE:$file $file 2>/dev/null || true; \
                 chmod --reference=$MASTER_NODE:$file $file 2>/dev/null || true" || true
            
            echo -e "  ${GREEN}✓ Синхронизировано${NC}"
        else
            echo -e "  ${RED}✗ Файл не существует на мастере${NC}"
        fi
    done
    
    # Перезапуск служб после синхронизации
    echo ""
    echo -e "${YELLOW}[СЛУЖБЫ] Перезапуск служб...${NC}"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "systemctl restart php-fpm && systemctl restart httpd && echo '  ✓ Службы перезапущены'" || \
    echo -e "  ${RED}✗ Ошибка перезапуска служб${NC}"
    
    echo ""
done

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  RSYNC СИНХРОНИЗАЦИЯ ЗАВЕРШЕНА${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "${GREEN}Все файлы синхронизированы!${NC}"
echo ""
echo -e "${YELLOW}Проверка:${NC}"
echo "  ssh root@10.0.1.221 'md5sum /etc/php-fpm.d/www.conf'"
echo "  ssh root@10.0.1.222 'md5sum /etc/php-fpm.d/www.conf'"
