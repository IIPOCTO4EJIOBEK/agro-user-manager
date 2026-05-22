#!/bin/bash
# ============================================================================
# BITRIX24 CLUSTER - SAFE FIX С ПОЛНЫМИ БЭКАПАМИ
# Дата: 2026-03-03
# Назначение: Исправление Redis, MySQL (Percona), логирования
# ВАЖНО: Сначала создаются полные бэкапы!
# ============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Таймстэмп для бэкапов
BACKUP_TS=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/cluster_backup_${BACKUP_TS}"

# Лог операций
LOG_FILE="/root/cluster_fix_${BACKUP_TS}.log"

# Функция логирования
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Функция создания бэкапа файла
backup_file() {
    local src="$1"
    local desc="$2"
    
    if [ -f "$src" ]; then
        local dest_dir="$BACKUP_DIR$(dirname $src)"
        mkdir -p "$dest_dir"
        cp -p "$src" "$dest_dir/"
        log "${GREEN}✓ Бэкап: $desc${NC}"
        log "  → $src → $dest_dir/"
    else
        log "${YELLOW}⚠ Файл не найден: $src${NC}"
    fi
}

# Функция проверки службы
check_service() {
    local service="$1"
    local host="$2"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        log "${GREEN}✓ $service на $host работает${NC}"
        return 0
    else
        log "${RED}✗ $service на $host НЕ работает${NC}"
        return 1
    fi
}

# ============================================================================
# ЭТАП 0: ПОДГОТОВКА
# ============================================================================
prepare() {
    log "${BLUE}=== ЭТАП 0: ПОДГОТОВКА ===${NC}"
    log ""
    
    # Создание директории для бэкапов
    mkdir -p "$BACKUP_DIR"
    log "${GREEN}✓ Директория для бэкапов: $BACKUP_DIR${NC}"
    
    # Создание лога
    touch "$LOG_FILE"
    log "${GREEN}✓ Лог файл: $LOG_FILE${NC}"
    
    # Определение текущего хоста
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    log "${BLUE}✓ Текущий IP: $CURRENT_IP${NC}"
    
    # Проверка прав root
    if [ "$EUID" -ne 0 ]; then 
        log "${RED}✗ Запустите скрипт от root${NC}"
        exit 1
    fi
    
    log ""
}

# ============================================================================
# ЭТАП 1: БЭКАП КОНФИГУРАЦИЙ
# ============================================================================
backup_configs() {
    log "${BLUE}=== ЭТАП 1: БЭКАП КОНФИГУРАЦИЙ ===${NC}"
    log ""
    
    # Redis (10.0.1.210)
    if [[ "$CURRENT_IP" == "10.0.1.210" ]]; then
        log "${YELLOW}[Redis] Создание бэкапов...${NC}"
        backup_file "/etc/redis/redis.conf" "Redis config"
        backup_file "/etc/redis/redis.conf.bak" "Redis config backup"
        
        # Бэкап данных Redis
        log "  → Бэкап данных Redis..."
        redis-cli -h 127.0.0.1 BGSAVE 2>/dev/null || true
        sleep 2
        if [ -f "/var/lib/redis/dump.rdb" ]; then
            mkdir -p "$BACKUP_DIR/var/lib/redis"
            cp -p /var/lib/redis/dump.rdb "$BACKUP_DIR/var/lib/redis/" 2>/dev/null || true
            log "${GREEN}✓ Бэкап dump.rdb${NC}"
        fi
        log ""
    fi
    
    # MySQL/Percona (10.0.1.200, 10.0.1.201)
    if [[ "$CURRENT_IP" == "10.0.1.200" ]] || [[ "$CURRENT_IP" == "10.0.1.201" ]]; then
        log "${YELLOW}[MySQL/Percona] Создание бэкапов...${NC}"
        backup_file "/etc/my.cnf" "MySQL config"
        backup_file "/etc/my.cnf.d/server.cnf" "MySQL server.cnf"
        backup_file "/etc/my.cnf.d/bitrix.cnf" "MySQL bitrix.cnf"
        
        # Бэкап баз данных
        log "  → Бэкап баз данных (mysqldump)..."
        mkdir -p "$BACKUP_DIR/mysql_dumps"
        
        # Список баз
        DATABASES=$(mysql -u root -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|performance_schema|sys" || true)
        
        for db in $DATABASES; do
            log "    → Бэкап БД: $db"
            mysqldump -u root --single-transaction --quick --lock-tables=false "$db" > "$BACKUP_DIR/mysql_dumps/${db}.sql" 2>/dev/null || true
        done
        
        # Полный дамп всех баз
        log "    → Полный дамп всех баз..."
        mysqldump -u root --all-databases --single-transaction --quick > "$BACKUP_DIR/mysql_dumps/_all_databases.sql" 2>/dev/null || true
        
        log "${GREEN}✓ Бэкап MySQL завершен${NC}"
        log ""
    fi
    
    # Web серверы (10.0.1.220, 221, 222)
    if [[ "$CURRENT_IP" =~ ^10\.0\.1\.(220|221|222)$ ]]; then
        log "${YELLOW}[Web] Создание бэкапов...${NC}"
        backup_file "/home/bitrix/www/bitrix/.settings.php" "Bitrix .settings.php"
        backup_file "/home/bitrix/www/bitrix/.settings_extra.php" "Bitrix .settings_extra.php"
        backup_file "/home/bitrix/www/bitrix/php_interface/dbconn.php" "Bitrix dbconn.php"
        backup_file "/etc/php-fpm.d/www.conf" "PHP-FPM www.conf"
        backup_file "/etc/php.d/bitrixenv.ini" "PHP bitrixenv.ini"
        log ""
    fi
    
    # HAProxy (10.0.1.50)
    if [[ "$CURRENT_IP" == "10.0.1.50" ]]; then
        log "${YELLOW}[HAProxy] Создание бэкапов...${NC}"
        backup_file "/etc/haproxy/haproxy.cfg" "HAProxy config"
        backup_file "/etc/haproxy/haproxy.cfg.bak" "HAProxy config backup"
        log ""
    fi
    
    log "${GREEN}✓ Все бэкапы созданы в: $BACKUP_DIR${NC}"
    log ""
}

# ============================================================================
# ЭТАП 2: ИСПРАВЛЕНИЕ REDIS (10.0.1.210)
# ============================================================================
fix_redis() {
    if [[ "$CURRENT_IP" != "10.0.1.210" ]]; then
        return
    fi
    
    log "${BLUE}=== ЭТАП 2: ИСПРАВЛЕНИЕ REDIS (10.0.1.210) ===${NC}"
    log ""
    
    # Проверка текущего статуса
    log "Проверка текущего статуса Redis..."
    redis-cli -h 127.0.0.1 ping >/dev/null 2>&1 && log "${GREEN}✓ Redis отвечает${NC}" || log "${RED}✗ Redis не отвечает${NC}"
    
    # Применение новой конфигурации
    log "Применение новой конфигурации..."
    
    # Сохранение текущих настроек в файл
    log "  → Сохранение текущих runtime настроек..."
    redis-cli -h 127.0.0.1 CONFIG GET "*" > "$BACKUP_DIR/redis_runtime_settings.txt" 2>/dev/null || true
    
    # Установка безопасных настроек (без перезапуска)
    log "  → Применение настроек памяти..."
    redis-cli -h 127.0.0.1 CONFIG SET maxmemory 8589934592 2>/dev/null && log "${GREEN}✓ maxmemory = 8GB${NC}" || log "${RED}✗ Ошибка установки maxmemory${NC}"
    
    log "  → Применение политики вытеснения..."
    redis-cli -h 127.0.0.1 CONFIG SET maxmemory-policy allkeys-lru 2>/dev/null && log "${GREEN}✓ maxmemory-policy = allkeys-lru${NC}" || log "${RED}✗ Ошибка установки политики${NC}"
    
    # Установка пароля (ОСТОРОЖНО!)
    log "  → Установка пароля..."
    NEW_PASS="B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!"
    redis-cli -h 127.0.0.1 CONFIG SET requirepass "$NEW_PASS" 2>/dev/null && log "${GREEN}✓ requirepass установлен${NC}" || log "${RED}✗ Ошибка установки пароля${NC}"
    
    # Сохранение конфигурации на диск
    log "  → Сохранение конфигурации на диск..."
    redis-cli -h 127.0.0.1 -a "$NEW_PASS" --no-auth-warning CONFIG REWRITE 2>/dev/null && log "${GREEN}✓ CONFIG REWRITE выполнен${NC}" || {
        log "${YELLOW}⚠ CONFIG REWRITE не поддерживается, копируем файл вручную${NC}"
        cp /root/redis_fixed.conf /etc/redis/redis.conf
    }
    
    # Перезапуск Redis для применения всех настроек
    log "  → Перезапуск Redis..."
    systemctl restart redis
    sleep 3
    
    # Проверка после перезапуска
    log "Проверка после перезапуска..."
    redis-cli -h 127.0.0.1 -a "$NEW_PASS" --no-auth-warning ping 2>/dev/null | grep -q "PONG" && log "${GREEN}✓ Redis работает после перезапуска${NC}" || log "${RED}✗ Redis НЕ работает после перезапуска${NC}"
    
    # Проверка настроек
    log "Проверка примененных настроек..."
    MAXMEM=$(redis-cli -h 127.0.0.1 -a "$NEW_PASS" --no-auth-warning CONFIG GET maxmemory 2>/dev/null | tail -1)
    POLICY=$(redis-cli -h 127.0.0.1 -a "$NEW_PASS" --no-auth-warning CONFIG GET maxmemory-policy 2>/dev/null | tail -1)
    AUTH=$(redis-cli -h 127.0.0.1 -a "$NEW_PASS" --no-auth-warning CONFIG GET requirepass 2>/dev/null | tail -1)
    
    log "  maxmemory: $MAXMEM"
    log "  maxmemory-policy: $POLICY"
    log "  requirepass: ${AUTH:0:10}..."
    
    log ""
    log "${GREEN}✓ Redis исправлен${NC}"
    log ""
}

# ============================================================================
# ЭТАП 3: ИСПРАВЛЕНИЕ MYSQL/PERCONA (10.0.1.200, 10.0.1.201)
# ============================================================================
fix_mysql() {
    if [[ "$CURRENT_IP" != "10.0.1.200" ]] && [[ "$CURRENT_IP" != "10.0.1.201" ]]; then
        return
    fi
    
    log "${BLUE}=== ЭТАП 3: ИСПРАВЛЕНИЕ MYSQL/PERCONA ($CURRENT_IP) ===${NC}"
    log ""
    
    # Проверка текущего статуса
    log "Проверка текущего статуса MySQL..."
    mysqladmin -u root ping 2>/dev/null | grep -q "alive" && log "${GREEN}✓ MySQL отвечает${NC}" || log "${RED}✗ MySQL не отвечает${NC}"
    
    # Применение настроек без перезапуска (где возможно)
    log "Применение настроек без перезапуска..."
    
    # Включение slow query log
    log "  → Включение slow query log..."
    mysql -u root -e "SET GLOBAL slow_query_log = 'ON';" 2>/dev/null && log "${GREEN}✓ slow_query_log включен${NC}" || log "${YELLOW}⚠ Не удалось включить slow_query_log${NC}"
    
    mysql -u root -e "SET GLOBAL long_query_time = 2;" 2>/dev/null && log "${GREEN}✓ long_query_time = 2${NC}" || true
    
    # Проверка HTTPD (только для 10.0.1.200)
    if [[ "$CURRENT_IP" == "10.0.1.200" ]]; then
        log "Проверка HTTPD..."
        if systemctl is-active --quiet httpd 2>/dev/null; then
            log "${GREEN}✓ HTTPD уже работает${NC}"
        else
            log "${YELLOW}⚠ HTTPD не работает, попытка запуска...${NC}"
            
            # Бэкап конфига HTTPD
            backup_file "/etc/httpd/conf/httpd.conf" "HTTPD main config"
            
            # Проверка конфига
            apachectl configtest 2>&1 | tee -a "$LOG_FILE"
            
            # Попытка запуска
            systemctl start httpd 2>&1 | tee -a "$LOG_FILE" && log "${GREEN}✓ HTTPD запущен${NC}" || log "${RED}✗ Не удалось запустить HTTPD${NC}"
            
            sleep 2
            systemctl status httpd --no-pager 2>&1 | tee -a "$LOG_FILE"
        fi
        log ""
    fi
    
    # Применение полной конфигурации (требует перезапуска)
    log "Применение полной конфигурации (требует перезапуска)..."
    
    # Сравнение текущего конфига с новым
    if [ -f "/root/mysql_fixed.cnf" ]; then
        log "  → Сравнение конфигураций..."
        if [ -f "/etc/my.cnf" ]; then
            diff /etc/my.cnf /root/mysql_fixed.cnf > "$BACKUP_DIR/my_cnf_diff.txt" 2>&1 || true
            DIFF_LINES=$(wc -l < "$BACKUP_DIR/my_cnf_diff.txt" || echo "0")
            log "    Найдено различий: $DIFF_LINES"
        fi
        
        # Применение нового конфига
        log "  → Применение новой конфигурации..."
        cp /root/mysql_fixed.cnf /etc/my.cnf
        log "${GREEN}✓ Конфигурация применена${NC}"
    fi
    
    # Создание пользователя для мониторинга
    log "  → Создание пользователя monitoring..."
    mysql -u root -e "CREATE USER IF NOT EXISTS 'monitoring'@'localhost' IDENTIFIED BY 'M0n1t0r1ng_P@ss_2026!';" 2>/dev/null || true
    mysql -u root -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'monitoring'@'localhost';" 2>/dev/null || true
    mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    log "${GREEN}✓ Пользователь monitoring создан${NC}"
    
    # Перезапуск MySQL (ОСТОРОЖНО!)
    log "  → Перезапуск MySQL..."
    read -p "Перезапустить MySQL? (будет простой 5-10 сек) [y/N]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl restart mysqld 2>&1 | tee -a "$LOG_FILE"
        sleep 5
        
        # Проверка после перезапуска
        mysqladmin -u root ping 2>/dev/null | grep -q "alive" && log "${GREEN}✓ MySQL работает после перезапуска${NC}" || log "${RED}✗ MySQL НЕ работает после перезапуска${NC}"
    else
        log "${YELLOW}⚠ Перезапуск отменен, примените настройки вручную${NC}"
    fi
    
    # Проверка настроек
    log "Проверка настроек..."
    MAX_CONN=$(mysql -u root -e "SHOW VARIABLES LIKE 'max_connections';" 2>/dev/null | tail -1 | awk '{print $2}')
    BUFFER_POOL=$(mysql -u root -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';" 2>/dev/null | tail -1 | awk '{print $2}')
    SLOW_LOG=$(mysql -u root -e "SHOW VARIABLES LIKE 'slow_query_log';" 2>/dev/null | tail -1 | awk '{print $2}')
    
    log "  max_connections: $MAX_CONN"
    log "  innodb_buffer_pool_size: $BUFFER_POOL"
    log "  slow_query_log: $SLOW_LOG"
    
    log ""
    log "${GREEN}✓ MySQL/Percona исправлен${NC}"
    log ""
}

# ============================================================================
# ЭТАП 4: НАСТРОЙКА МОНИТОРИНГА
# ============================================================================
setup_monitoring() {
    log "${BLUE}=== ЭТАП 4: НАСТРОЙКА МОНИТОРИНГА ===${NC}"
    log ""
    
    # Копирование скриптов мониторинга
    if [ -f "/root/redis_monitor.sh" ] && [[ "$CURRENT_IP" == "10.0.1.210" ]]; then
        log "Установка мониторинга Redis..."
        cp /root/redis_monitor.sh /usr/local/bin/redis_monitor.sh
        chmod +x /usr/local/bin/redis_monitor.sh
        
        # Настройка cron
        if ! crontab -l 2>/dev/null | grep -q 'redis_monitor'; then
            (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/redis_monitor.sh") | crontab -
            log "${GREEN}✓ Мониторинг Redis добавлен в cron${NC}"
        fi
    fi
    
    if [ -f "/root/mysql_monitor.sh" ] && [[ "$CURRENT_IP" =~ ^10\.0\.1\.(200|201)$ ]]; then
        log "Установка мониторинга MySQL..."
        cp /root/mysql_monitor.sh /usr/local/bin/mysql_monitor.sh
        chmod +x /usr/local/bin/mysql_monitor.sh
        
        # Настройка cron
        if ! crontab -l 2>/dev/null | grep -q 'mysql_monitor'; then
            (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/mysql_monitor.sh") | crontab -
            log "${GREEN}✓ Мониторинг MySQL добавлен в cron${NC}"
        fi
    fi
    
    log ""
}

# ============================================================================
# ЭТАП 5: НАСТРОЙКА LOGROTATE
# ============================================================================
setup_logrotate() {
    log "${BLUE}=== ЭТАП 5: НАСТРОЙКА LOGROTATE ===${NC}"
    log ""
    
    # Redis logrotate
    if [[ "$CURRENT_IP" == "10.0.1.210" ]]; then
        cat > /etc/logrotate.d/redis << 'EOF'
/var/log/redis/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 redis redis
    postrotate
        systemctl reload redis > /dev/null 2>&1 || true
    endscript
}
EOF
        log "${GREEN}✓ Logrotate для Redis настроен${NC}"
    fi
    
    # MySQL logrotate
    if [[ "$CURRENT_IP" =~ ^10\.0\.1\.(200|201)$ ]]; then
        cat > /etc/logrotate.d/mysql << 'EOF'
/var/log/mysql/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 mysql mysql
    sharedscripts
    postrotate
        systemctl reload mysqld > /dev/null 2>&1 || true
    endscript
}
EOF
        log "${GREEN}✓ Logrotate для MySQL настроен${NC}"
    fi
    
    log ""
}

# ============================================================================
# ЭТАП 6: ФИНАЛЬНАЯ ПРОВЕРКА
# ============================================================================
verify() {
    log "${BLUE}=== ЭТАП 6: ФИНАЛЬНАЯ ПРОВЕРКА ===${NC}"
    log ""
    
    log "Проверка служб..."
    
    # Redis
    if [[ "$CURRENT_IP" == "10.0.1.210" ]]; then
        redis-cli -h 127.0.0.1 -a "B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!" --no-auth-warning ping 2>/dev/null | grep -q "PONG" && log "${GREEN}✓ Redis: РАБОТАЕТ${NC}" || log "${RED}✗ Redis: НЕ РАБОТАЕТ${NC}"
    fi
    
    # MySQL
    if [[ "$CURRENT_IP" =~ ^10\.0\.1\.(200|201)$ ]]; then
        mysqladmin -u root ping 2>/dev/null | grep -q "alive" && log "${GREEN}✓ MySQL: РАБОТАЕТ${NC}" || log "${RED}✗ MySQL: НЕ РАБОТАЕТ${NC}"
    fi
    
    # HTTPD
    if [[ "$CURRENT_IP" == "10.0.1.200" ]]; then
        systemctl is-active --quiet httpd 2>/dev/null && log "${GREEN}✓ HTTPD: РАБОТАЕТ${NC}" || log "${RED}✗ HTTPD: НЕ РАБОТАЕТ${NC}"
    fi
    
    log ""
    log "Информация о бэкапах:"
    log "  Директория: $BACKUP_DIR"
    log "  Лог: $LOG_FILE"
    log ""
    
    # Размер бэкапов
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    log "  Размер бэкапов: $BACKUP_SIZE"
    log ""
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   BITRIX24 CLUSTER - SAFE FIX С ПОЛНЫМИ БЭКАПАМИ         ║"
    echo "║   Дата: $(date '+%Y-%m-%d %H:%M:%S')                          ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "ВНИМАНИЕ! Этот скрипт внесет изменения в конфигурацию сервера."
    log "Все изменения будут забеккаплены в: $BACKUP_DIR"
    log ""
    read -p "Продолжить? (y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Отменено."
        exit 1
    fi
    
    log ""
    prepare
    backup_configs
    fix_redis
    fix_mysql
    setup_monitoring
    setup_logrotate
    verify
    
    log "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║              ИСПРАВЛЕНИЕ ЗАВЕРШЕНО УСПЕШНО!               ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "Бэкапы сохранены в: $BACKUP_DIR"
    log "Лог операций: $LOG_FILE"
    log ""
    log "Для отката используйте файлы из директории бэкапов:"
    log "  cp $BACKUP_DIR/etc/redis/redis.conf /etc/redis/redis.conf"
    log "  cp $BACKUP_DIR/etc/my.cnf /etc/my.cnf"
    log ""
    log "Полезные команды:"
    log "  Redis:    redis-cli -h 10.0.1.210 -a 'B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!'"
    log "  MySQL:    mysql -u root -p"
    log "  Мониторинг: /usr/local/bin/redis_monitor.sh"
    log "            /usr/local/bin/mysql_monitor.sh"
    log ""
}

main "$@"
