#!/bin/bash
# ============================================================================
# BITRIX24 CLUSTER - СИНХРОНИЗАЦИЯ ВЕБ-УЗЛОВ
# Синхронизирует конфигурационные файлы на всех веб-узлах кластера
# ============================================================================

set -e

# Конфигурация
CLUSTER_WEB_NODES=("10.0.1.220" "10.0.1.221" "10.0.1.222")
SSH_USER="root"
SSH_PASS="!P09710023p"
SSH_PORT="22"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  BITRIX24 CLUSTER - СИНХРОНИЗАЦИЯ ВЕБ-УЗЛОВ${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Файлы для синхронизации
declare -A SYNC_FILES=(
    ["/home/bitrix/www/bitrix/license_key.php"]="<? \$LICENSE_KEY = \"P25-ML-PLBNQN7UM28BGK5XQMSI\"; ?>\n"
)

# Синхронизация файлов
for node in "${CLUSTER_WEB_NODES[@]}"; do
    echo -e "${BLUE}[УЗЕЛ] $node${NC}"
    
    for file in "${!SYNC_FILES[@]}"; do
        echo -e "${YELLOW}  Синхронизация: $file${NC}"
        
        sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" << EOF
# Создаем резервную копию
cp $file ${file}.bak.\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Записываем правильное содержимое
cat > $file << 'FILEOF'
<? \$LICENSE_KEY = "P25-ML-PLBNQN7UM28BGK5XQMSI"; ?>
FILEOF

# Устанавливаем права
chown bitrix:bitrix $file
chmod 644 $file

# Проверяем
md5sum $file
echo "  ✓ Файл синхронизирован"
EOF
    done
    
    # Очистка OPcache
    echo -e "${YELLOW}  Очистка OPcache...${NC}"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "rm -rf /var/lib/php/opcache/* 2>/dev/null && systemctl restart httpd && echo '  ✓ OPcache очищен, Apache перезапущен'"
    
    echo ""
done

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  СИНХРОНИЗАЦИЯ ЗАВЕРШЕНА${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "${YELLOW}Проверка:${NC}"
echo "curl -k 'https://b24.ahprostory.ru/bitrix/admin/site_checker.php'"
