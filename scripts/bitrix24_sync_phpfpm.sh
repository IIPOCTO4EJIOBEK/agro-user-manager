#!/bin/bash
# ============================================================================
# BITRIX24 CLUSTER - СИНХРОНИЗАЦИЯ PHP-FPM КОНФИГУРАЦИИ
# Синхронизирует настройки PHP-FPM на всех веб-узлах кластера
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
echo -e "${BLUE}  BITRIX24 CLUSTER - СИНХРОНИЗАЦИЯ PHP-FPM${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Конфигурация PHP-FPM для всех узлов
PHP_FPM_CONFIG='[www]
user = bitrix
group = bitrix

listen = /run/php-fpm/www.sock
listen.owner = bitrix
listen.group = bitrix
listen.mode = 0660

pm = dynamic
pm.max_children = 100
pm.start_servers = 20
pm.min_spare_servers = 10
pm.max_spare_servers = 30
pm.max_requests = 1000

pm.status_path = /fpm-status
ping.path = /fpm-ping
ping.response = pong

env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp

security.limit_extensions = .php .php3 .php4 .php5 .phar
php_admin_value[open_basedir] = /home/bitrix/www:/tmp:/var/tmp
php_admin_value[session.save_path] = /tmp/php_sessions/www
php_admin_value[upload_tmp_dir] = /tmp/php_upload/www'

# Конфигурация Apache для PHP-FPM
APACHE_PHP_CONFIG='#
# PHP-FPM Configuration for Apache
#

# Deny access to .user.ini files
<Files ".user.ini">
    <IfModule mod_authz_core.c>
        Require all denied
    </IfModule>
    <IfModule !mod_authz_core.c>
        Order allow,deny
        Deny from all
        Satisfy All
    </IfModule>
</Files>

# Add index.php to directory indexes
DirectoryIndex index.php

# Enable http authorization headers
SetEnvIfNoCase ^Authorization$ "(.+)" HTTP_AUTHORIZATION=$1

# PHP-FPM via proxy_fcgi
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost"
</FilesMatch>

# Prevent PHP from processing certain files
<FilesMatch \.(phps|phpt)$>
    SetHandler None
</FilesMatch>'

# Синхронизация на всех узлах
for node in "${CLUSTER_WEB_NODES[@]}"; do
    echo -e "${BLUE}[УЗЕЛ] $node${NC}"
    
    # Синхронизация PHP-FPM конфигурации
    echo -e "${YELLOW}  Синхронизация PHP-FPM конфигурации...${NC}"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" << EOF
# Резервная копия
cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf.bak.\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Запись новой конфигурации
cat > /etc/php-fpm.d/www.conf << 'PHPEOF'
$PHP_FPM_CONFIG
PHPEOF

echo "  ✓ PHP-FPM конфигурация обновлена"
EOF
    
    # Синхронизация Apache конфигурации
    echo -e "${YELLOW}  Синхронизация Apache PHP конфигурации...${NC}"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" << EOF
# Резервная копия
cp /etc/httpd/conf.d/php.conf /etc/httpd/conf.d/php.conf.bak.\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Запись новой конфигурации
cat > /etc/httpd/conf.d/php.conf << 'APACHEEOF'
$APACHE_PHP_CONFIG
APACHEEOF

echo "  ✓ Apache конфигурация обновлена"
EOF
    
    # Создание директорий для сессий и загрузок
    echo -e "${YELLOW}  Создание директорий...${NC}"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "mkdir -p /tmp/php_sessions/www /tmp/php_upload/www && chown -R bitrix:bitrix /tmp/php_sessions/www /tmp/php_upload/www && chmod 770 /tmp/php_sessions/www /tmp/php_upload/www && echo '  ✓ Директории созданы'"
    
    # Перезапуск служб
    echo -e "${YELLOW}  Перезапуск служб...${NC}"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "systemctl restart php-fpm && systemctl restart httpd && echo '  ✓ Службы перезапущены'"
    
    # Проверка статуса
    echo -e "${YELLOW}  Проверка статуса...${NC}"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$node" \
        "echo '  PHP-FPM:' \$(systemctl is-active php-fpm); echo '  Apache:' \$(systemctl is-active httpd)"
    
    echo ""
done

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  СИНХРОНИЗАЦИЯ PHP-FPM ЗАВЕРШЕНА${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "${GREEN}Все узлы кластера синхронизированы!${NC}"
echo ""
echo -e "${YELLOW}Проверка:${NC}"
echo "curl -k 'https://b24.ahprostory.ru/bitrix/admin/site_checker.php'"
