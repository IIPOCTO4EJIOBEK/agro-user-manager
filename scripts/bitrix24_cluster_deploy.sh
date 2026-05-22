#!/bin/bash
# ============================================================================
# BITRIX24 CLUSTER CONFIGURATION DEPLOYMENT SCRIPT
# Развертывание исправленной конфигурации Nginx на всех узлах кластера
# ============================================================================

set -e

# Конфигурация
CLUSTER_NODES=("10.0.1.220" "10.0.1.221" "10.0.1.222")
SSH_USER="vardo001"
SSH_PASS="!P09710023p"
SSH_PORT="22"
SOURCE_CONFIG="/root/99-proxy.conf.bitrix24_fixed"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  РАЗВЕРТЫВАНИЕ КОНФИГУРАЦИИ BITRIX24 НА КЛАСТЕРЕ${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Проверка доступности файла конфигурации
if [ ! -f "$SOURCE_CONFIG" ]; then
    echo -e "${RED}Ошибка: Файл конфигурации не найден: $SOURCE_CONFIG${NC}"
    exit 1
fi

# Развертывание на каждом узле
for node in "${CLUSTER_NODES[@]}"; do
    echo -e "${BLUE}[УЗЕЛ] $node${NC}"
    echo -e "${YELLOW}  Шаг 1: Создание резервной копии...${NC}"
    
    # Создаем резервную копию
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "sudo cp /etc/nginx/conf.d/99-proxy.conf /etc/nginx/conf.d/99-proxy.conf.backup.\$(date +%Y%m%d_%H%M%S) 2>/dev/null" || \
    echo -e "${YELLOW}  Предупреждение: Не удалось создать резервную копию${NC}"
    
    echo -e "${YELLOW}  Шаг 2: Копирование новой конфигурации...${NC}"
    
    # Копируем новый конфиг
    if sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no -P "$SSH_PORT" \
        "$SOURCE_CONFIG" "$SSH_USER@$node:/tmp/99-proxy.conf.new" 2>/dev/null; then
        echo -e "${GREEN}  ✓ Конфигурация скопирована${NC}"
    else
        echo -e "${RED}  ✗ Ошибка копирования конфигурации${NC}"
        continue
    fi
    
    echo -e "${YELLOW}  Шаг 3: Установка и проверка конфигурации...${NC}"
    
    # Устанавливаем и проверяем конфиг
    if sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" << 'ENDSSH'
echo "$SSH_PASS" | sudo -S mv /tmp/99-proxy.conf.new /etc/nginx/conf.d/99-proxy.conf
if echo "$SSH_PASS" | sudo -S nginx -t 2>&1; then
    echo "Конфигурация проверена, перезагрузка nginx..."
    echo "$SSH_PASS" | sudo -S systemctl reload nginx
    echo "Nginx перезапущен успешно"
else
    echo "Ошибка проверки конфигурации! Восстановление..."
    echo "$SSH_PASS" | sudo -S mv /etc/nginx/conf.d/99-proxy.conf.backup.* /etc/nginx/conf.d/99-proxy.conf 2>/dev/null || true
    exit 1
fi
ENDSSH
    then
        echo -e "${GREEN}  ✓ Развертывание успешно${NC}"
    else
        echo -e "${RED}  ✗ Развертывание не удалось${NC}"
    fi
    
    echo ""
done

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo "1. Проверьте работу Bitrix24 site checker"
echo "2. Мониторьте логи на наличие ошибок UNIQUE ID"
echo "3. Убедитесь, что все узлы кластера отвечают"
echo ""
echo -e "URL: https://b24.ahprostory.ru/bitrix/admin/site_checker.php"
