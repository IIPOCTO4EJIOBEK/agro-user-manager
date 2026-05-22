# 📋 ИНСТРУКЦИЯ ПО ИСПРАВЛЕНИЮ REDIS, БАЗ ДАННЫХ И ЛОГИРОВАНИЯ
## Bitrix24 Cluster Fix
## Дата: 2026-03-03

---

## 🎯 ЦЕЛЬ

Исправить критические проблемы с:
1. **Redis** — отсутствие ограничений памяти и аутентификации
2. **MySQL** — оптимизация конфигурации и логирование
3. **PostgreSQL** — оптимизация конфигурации и логирование
4. **HTTPD** — запуск службы на DB Primary
5. **Логирование** — настройка мониторинга и ротации логов

---

## 📁 СОЗДАННЫЕ ФАЙЛЫ

| Файл | Назначение | Куда применять |
|------|------------|----------------|
| `redis_fixed.conf` | Исправленная конфигурация Redis | 10.0.1.210 |
| `mysql_fixed.cnf` | Исправленная конфигурация MySQL | 10.0.1.200 |
| `postgresql_fixed.conf` | Исправленная конфигурация PostgreSQL | 10.0.1.200 |
| `redis_monitor.sh` | Скрипт мониторинга Redis | 10.0.1.210 |
| `mysql_monitor.sh` | Скрипт мониторинга MySQL | 10.0.1.200 |
| `postgresql_monitor.sh` | Скрипт мониторинга PostgreSQL | 10.0.1.200 |
| `bitrix24_fix_redis_dbs_logs.sh` | Автоматический скрипт исправления | Все серверы |

---

## 🔧 ПРИМЕНЕНИЕ ИСПРАВЛЕНИЙ

### ВАРИАНТ 1: Автоматическое исправление (РЕКОМЕНДУЕТСЯ)

```bash
# 1. Подключиться к серверу
ssh vardo001@10.0.1.200  # DB Primary

# 2. Скопировать скрипт на сервер
scp /root/bitrix24_fix_redis_dbs_logs.sh vardo001@10.0.1.200:/root/

# 3. Выполнить скрипт
ssh vardo001@10.0.1.200
cd /root
./bitrix24_fix_redis_dbs_logs.sh
```

Скрипт автоматически:
- Создаст резервные копии конфигов
- Применит новые конфигурации
- Настроит логирование
- Перезапустит службы
- Настроит мониторинг в cron

---

### ВАРИАНТ 2: Ручное исправление

#### 1. ИСПРАВЛЕНИЕ REDIS (10.0.1.210)

```bash
# Подключиться к серверу
ssh vardo001@10.0.1.210

# Создать резервную копию
sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.backup.$(date +%Y%m%d_%H%M%S)

# Скопировать новый конфиг
sudo cp /root/redis_fixed.conf /etc/redis/redis.conf

# Создать директории для логов
sudo mkdir -p /var/log/redis
sudo chown redis:redis /var/log/redis
sudo chmod 755 /var/log/redis

# Перезапустить Redis
sudo systemctl restart redis

# Проверить статус
sudo systemctl status redis
redis-cli -h 10.0.1.210 ping
```

**Проверка:**
```bash
# Проверить память
redis-cli -h 10.0.1.210 INFO memory | grep maxmemory

# Проверить аутентификацию
redis-cli -h 10.0.1.210 CONFIG GET requirepass

# Должно вернуть:
# maxmemory: 8589934592 (8GB)
# requirepass: "B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!"
```

---

#### 2. ИСПРАВЛЕНИЕ MYSQL (10.0.1.200)

```bash
# Подключиться к серверу
ssh vardo001@10.0.1.200

# Создать резервную копию
sudo cp /etc/my.cnf /etc/my.cnf.backup.$(date +%Y%m%d_%H%M%S)

# Скопировать новый конфиг
sudo cp /root/mysql_fixed.cnf /etc/my.cnf

# Создать директории для логов
sudo mkdir -p /var/log/mysql
sudo chown mysql:mysql /var/log/mysql
sudo chmod 755 /var/log/mysql

# Создать пользователя для мониторинга
mysql -u root -e "CREATE USER IF NOT EXISTS 'monitoring'@'%' IDENTIFIED BY 'M0n1t0r1ng_P@ss_2026!';"
mysql -u root -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'monitoring'@'%';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Перезапустить MySQL
sudo systemctl restart mysqld

# Проверить статус
sudo systemctl status mysqld
mysqladmin -u root ping
```

**Проверка:**
```bash
# Проверить конфигурацию
mysql -u root -e "SHOW VARIABLES LIKE 'max_connections';"
mysql -u root -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
mysql -u root -e "SHOW VARIABLES LIKE 'slow_query_log';"

# Проверить логи
tail -100 /var/log/mysql/error.log
tail -100 /var/log/mysql/slow.log
```

---

#### 3. ИСПРАВЛЕНИЕ POSTGRESQL (10.0.1.200)

```bash
# Подключиться к серверу
ssh vardo001@10.0.1.200

# Создать резервную копию
sudo cp /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf.backup.$(date +%Y%m%d_%H%M%S)

# Скопировать новый конфиг
sudo cp /root/postgresql_fixed.conf /var/lib/pgsql/data/postgresql.conf

# Создать директории для логов
sudo mkdir -p /var/log/postgresql
sudo chown postgres:postgres /var/log/postgresql
sudo chmod 755 /var/log/postgresql

# Создать пользователя для мониторинга
sudo -u postgres psql -c "CREATE USER monitoring WITH PASSWORD 'M0n1t0r1ng_P@ss_2026!';"
sudo -u postgres psql -c "GRANT pg_monitor TO monitoring;"

# Перезапустить PostgreSQL
sudo systemctl restart postgresql

# Проверить статус
sudo systemctl status postgresql
sudo -u postgres psql -c "SELECT 1;"
```

**Проверка:**
```bash
# Проверить конфигурацию
sudo -u postgres psql -c "SHOW max_connections;"
sudo -u postgres psql -c "SHOW shared_buffers;"
sudo -u postgres psql -c "SHOW log_min_duration_statement;"

# Проверить логи
tail -100 /var/log/postgresql/postgresql-*.log
```

---

#### 4. ИСПРАВЛЕНИЕ HTTPD (10.0.1.200)

```bash
# Подключиться к серверу
ssh vardo001@10.0.1.200

# Проверить логи
sudo journalctl -u httpd -n 50 --no-pager

# Попытаться запустить
sudo systemctl start httpd

# Проверить статус
sudo systemctl status httpd

# Если не запускается, проверить конфиг
sudo apachectl configtest
```

---

## 📊 НАСТРОЙКА МОНИТОРИНГА

### Установка скриптов мониторинга

```bash
# На 10.0.1.210 (Redis)
scp /root/redis_monitor.sh vardo001@10.0.1.210:/usr/local/bin/
ssh vardo001@10.0.1.210 "chmod +x /usr/local/bin/redis_monitor.sh"

# На 10.0.1.200 (MySQL/PostgreSQL)
scp /root/mysql_monitor.sh vardo001@10.0.1.200:/usr/local/bin/
scp /root/postgresql_monitor.sh vardo001@10.0.1.200:/usr/local/bin/
ssh vardo001@10.0.1.200 "chmod +x /usr/local/bin/mysql_monitor.sh /usr/local/bin/postgresql_monitor.sh"
```

### Настройка cron (каждые 5 минут)

```bash
# Добавить в crontab
crontab -e

# Добавить строки:
*/5 * * * * /usr/local/bin/redis_monitor.sh
*/5 * * * * /usr/local/bin/mysql_monitor.sh
*/5 * * * * /usr/local/bin/postgresql_monitor.sh
```

---

## 🔍 ПРОСМОТР ЛОГОВ

### Redis логи
```bash
# Текущие логи
tail -100 /var/log/redis/redis-server.log

# Логи мониторинга
tail -100 /var/log/redis/monitoring.log

# В реальном времени
tail -f /var/log/redis/redis-server.log
```

### MySQL логи
```bash
# Ошибки
tail -100 /var/log/mysql/error.log

# Медленные запросы
tail -100 /var/log/mysql/slow.log

# Логи мониторинга
tail -100 /var/log/mysql/monitoring.log
```

### PostgreSQL логи
```bash
# Логи
ls -la /var/log/postgresql/
tail -100 /var/log/postgresql/postgresql-*.log

# Логи мониторинга
tail -100 /var/log/postgresql/monitoring.log
```

---

## ⚙️ КОМАНДЫ ДЛЯ ПРОВЕРКИ

### Redis
```bash
# Основная информация
redis-cli -h 10.0.1.210 -a "PASSWORD" INFO

# Проверка памяти
redis-cli -h 10.0.1.210 -a "PASSWORD" INFO memory | grep -E "maxmemory|used_memory"

# Проверка подключений
redis-cli -h 10.0.1.210 -a "PASSWORD" INFO clients

# Проверка баз данных
for i in 0 1 2 3 4; do
    echo "DB $i: $(redis-cli -h 10.0.1.210 -a "PASSWORD" -n $i DBSIZE)"
done
```

### MySQL
```bash
# Основная информация
mysqladmin -u root status

# Подключения
mysql -u root -e "SHOW STATUS LIKE 'Threads_connected';"

# Buffer Pool
mysql -u root -e "SHOW ENGINE INNODB STATUS\G" | grep -A 5 "BUFFER POOL"

# Медленные запросы
mysql -u root -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';"
```

### PostgreSQL
```bash
# Основная информация
sudo -u postgres psql -c "SELECT version();"

# Подключения
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# Размер баз данных
sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database ORDER BY pg_database_size(datname) DESC;"

# Репликация
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"
```

---

## 🚨 УСТРАНЕНИЕ ПРОБЛЕМ

### Redis не запускается
```bash
# Проверить логи
tail -100 /var/log/redis/redis-server.log

# Проверить права
ls -la /etc/redis/redis.conf
ls -la /var/log/redis/
ls -la /var/lib/redis/

# Исправить права
chown redis:redis /etc/redis/redis.conf
chown -R redis:redis /var/log/redis/
chown -R redis:redis /var/lib/redis/
```

### MySQL не запускается
```bash
# Проверить логи
tail -100 /var/log/mysql/error.log

# Проверить конфиг
mysqld --validate-config

# Проверить права
ls -la /etc/my.cnf
ls -la /var/log/mysql/
ls -la /var/lib/mysql/
```

### PostgreSQL не запускается
```bash
# Проверить логи
tail -100 /var/log/postgresql/postgresql-*.log

# Проверить конфиг
sudo -u postgres postgres -C config_file

# Проверить права
ls -la /var/lib/pgsql/data/postgresql.conf
ls -la /var/log/postgresql/
```

---

## 📈 МОНИТОРИНГ В РЕАЛЬНОМ ВРЕМЕНИ

### Redis
```bash
watch -n 1 'redis-cli -h 10.0.1.210 -a "PASSWORD" INFO stats | grep -E "ops_per_sec|keyspace_hits|keyspace_misses"'
```

### MySQL
```bash
watch -n 1 'mysql -u root -e "SHOW STATUS LIKE \"Threads_connected\"; SHOW STATUS LIKE \"Queries\";"'
```

### PostgreSQL
```bash
watch -n 1 'sudo -u postgres psql -c "SELECT count(*) as connections FROM pg_stat_activity;"'
```

---

## ✅ ПРОВЕРОЧНЫЙ ЛИСТ

После применения исправлений проверьте:

- [ ] Redis работает (PONG)
- [ ] Redis maxmemory = 8GB
- [ ] Redis requirepass установлен
- [ ] MySQL работает (alive)
- [ ] MySQL slow_query_log включен
- [ ] PostgreSQL работает
- [ ] PostgreSQL логирование включено
- [ ] HTTPD запущен
- [ ] Скрипты мониторинга установлены
- [ ] Cron задания настроены
- [ ] Логи пишутся в файлы

---

## 🔐 БЕЗОПАСНОСТЬ

### После установки смените пароли:

**Redis:**
```bash
redis-cli -h 10.0.1.210
CONFIG SET requirepass "YOUR_NEW_STRONG_PASSWORD"
```

**MySQL:**
```bash
mysql -u root -e "ALTER USER 'monitoring'@'%' IDENTIFIED BY 'YOUR_NEW_PASSWORD';"
```

**PostgreSQL:**
```bash
sudo -u postgres psql -c "ALTER USER monitoring WITH PASSWORD 'YOUR_NEW_PASSWORD';"
```

---

## 📞 ПОДДЕРЖКА

При возникновении проблем:

1. Проверьте логи служб
2. Проверьте логи мониторинга
3. Используйте команды для проверки выше
4. При необходимости восстановите резервные копии:
   ```bash
   cp /etc/redis/redis.conf.backup.* /etc/redis/redis.conf
   cp /etc/my.cnf.backup.* /etc/my.cnf
   cp /var/lib/pgsql/data/postgresql.conf.backup.* /var/lib/pgsql/data/postgresql.conf
   ```

---

**ВРЕМЯ ПРИМЕНЕНИЯ:** ~15-30 минут
**ПЕРЕРЫВ В РАБОТЕ:** Требуется перезапуск служб (5-10 секунд простоя)
**ОТКАТ:** Автоматически через резервные копии
