# 🛡️ БЕЗОПАСНОЕ ИСПРАВЛЕНИЕ BITRIX24 CLUSTER
## С ПОЛНЫМИ БЭКАПАМИ

---

## ⚠️ ВАЖНО

Этот скрипт **НЕ СЛОМАЕТ** вашу систему, потому что:

1. **Сначала создаются полные бэкапы** всех конфигураций
2. **Каждое изменение проверяется** после применения
3. **Есть возможность отката** к исходному состоянию
4. **Перезапуск служб только с подтверждения**

---

## 📁 ЧТО БУДЕТ СДЕЛАНО

### 1. БЭКАПЫ (Сначала!)

| Что | Куда | Format |
|-----|------|--------|
| Конфиги Redis | `/root/cluster_backup_YYYYMMDD_HHMMSS/etc/redis/` | Копия файла |
| Данные Redis | `/root/cluster_backup_.../var/lib/redis/` | dump.rdb |
| Конфиги MySQL | `/root/cluster_backup_.../etc/` | Копия файла |
| Базы данных | `/root/cluster_backup_.../mysql_dumps/` | SQL дампы |
| Runtime настройки | `/root/cluster_backup_.../redis_runtime_settings.txt` | Текст |

### 2. ИСПРАВЛЕНИЯ

| Сервер | Что исправляется |
|--------|------------------|
| **10.0.1.210** (Redis) | maxmemory=8GB, requirepass, maxmemory-policy |
| **10.0.1.200** (Percona) | slow_query_log, long_query_time, HTTPD запуск |
| **10.0.1.201** (Percona) | slow_query_log, long_query_time |

### 3. МОНИТОРИНГ

| Скрипт | Куда | Интервал |
|--------|------|----------|
| redis_monitor.sh | /usr/local/bin/ | 5 мин (cron) |
| mysql_monitor.sh | /usr/local/bin/ | 5 мин (cron) |

### 4. LOGROTATE

| Служба | Конфиг |
|--------|--------|
| Redis | /etc/logrotate.d/redis |
| MySQL | /etc/logrotate.d/mysql |

---

## 🚀 ПРИМЕНЕНИЕ

### На каждом сервере отдельно:

```bash
# 1. Подключиться к серверу
ssh root@10.0.1.210  # Redis
ssh root@10.0.1.200  # MySQL Primary
ssh root@10.0.1.201  # MySQL Replica
```

```bash
# 2. Скопировать скрипт
scp /root/bitrix24_safe_fix.sh root@10.0.1.210:/root/
scp /root/bitrix24_safe_fix.sh root@10.0.1.200:/root/
scp /root/bitrix24_safe_fix.sh root@10.0.1.201:/root/
```

```bash
# 3. Выполнить на каждом сервере
ssh root@10.0.1.210
cd /root
./bitrix24_safe_fix.sh
```

---

## 📋 ПОШАГОВЫЙ ПРОЦЕСС

### ЭТАП 0: Подготовка
- Создание директории для бэкапов
- Определение текущего сервера
- Проверка прав root

### ЭТАП 1: Бэкап конфигураций
- Копирование всех конфигов
- Дамп баз данных MySQL
- Сохранение runtime настроек Redis

### ЭТАП 2: Исправление Redis (только 10.0.1.210)
- Установка maxmemory = 8GB
- Установка maxmemory-policy = allkeys-lru
- Установка requirepass (пароль)
- **Перезапуск с проверкой**

### ЭТАП 3: Исправление MySQL (только 10.0.1.200, 201)
- Включение slow_query_log
- Настройка long_query_time = 2 сек
- Запуск HTTPD (только 10.0.1.200)
- **Перезапуск MySQL с подтверждения**

### ЭТАП 4: Настройка мониторинга
- Копирование скриптов
- Настройка cron (каждые 5 мин)

### ЭТАП 5: Настройка logrotate
- Ротация логов Redis (30 дней)
- Ротация логов MySQL (30 дней)

### ЭТАП 6: Финальная проверка
- Проверка всех служб
- Вывод информации о бэкапах

---

## 🔐 БЕЗОПАСНОСТЬ

### Пароли (по умолчанию):

| Служба | Пароль |
|--------|--------|
| Redis | `B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!` |
| MySQL monitoring | `M0n1t0r1ng_P@ss_2026!` |

### После установки смените пароли!

---

## ↩️ ОТКАТ К ИСХОДНОМУ СОСТОЯНИЮ

Если что-то пошло не так:

### Redis откат (10.0.1.210):
```bash
# Найти последний бэкап
ls -la /root/cluster_backup_*/

# Восстановить конфиг
cp /root/cluster_backup_*/etc/redis/redis.conf /etc/redis/redis.conf

# Восстановить данные
cp /root/cluster_backup_*/var/lib/redis/dump.rdb /var/lib/redis/

# Перезапустить
systemctl restart redis
```

### MySQL откат (10.0.1.200, 201):
```bash
# Восстановить конфиг
cp /root/cluster_backup_*/etc/my.cnf /etc/my.cnf

# Перезапустить
systemctl restart mysqld

# Восстановить БД из дампа (если нужно)
mysql -u root < /root/cluster_backup_*/mysql_dumps/_all_databases.sql
```

---

## 📊 ПРОВЕРКА ПОСЛЕ ИСПРАВЛЕНИЯ

### Redis (10.0.1.210):
```bash
# Проверка подключения
redis-cli -h 10.0.1.210 -a 'B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!' ping
# Должен вернуть: PONG

# Проверка памяти
redis-cli -h 10.0.1.210 -a 'B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!' INFO memory | grep maxmemory

# Проверка настроек
redis-cli -h 10.0.1.210 -a 'B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!' CONFIG GET maxmemory
redis-cli -h 10.0.1.210 -a 'B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!' CONFIG GET requirepass
```

### MySQL (10.0.1.200, 201):
```bash
# Проверка подключения
mysqladmin -u root ping
# Должен вернуть: alive

# Проверка настроек
mysql -u root -e "SHOW VARIABLES LIKE 'slow_query_log';"
mysql -u root -e "SHOW VARIABLES LIKE 'long_query_time';"
mysql -u root -e "SHOW VARIABLES LIKE 'max_connections';"
```

### HTTPD (10.0.1.200):
```bash
# Проверка статуса
systemctl status httpd

# Проверка логов
tail -100 /var/log/httpd/error_log
```

---

## 📞 ЕСЛИ ЧТО-ТО ПОШЛО НЕ ТАК

### 1. Проверьте логи скрипта:
```bash
cat /root/cluster_fix_YYYYMMDD_HHMMSS.log
```

### 2. Проверьте бэкапы:
```bash
ls -la /root/cluster_backup_*/
```

### 3. Восстановите из бэкапа:
```bash
# Пример для Redis
cp /root/cluster_backup_*/etc/redis/redis.conf /etc/redis/redis.conf
systemctl restart redis
```

### 4. Проверьте службы:
```bash
systemctl status redis
systemctl status mysqld
systemctl status httpd
```

---

## ✅ ПРОВЕРОЧНЫЙ ЛИСТ

После применения на всех серверах:

- [ ] Бэкапы созданы (директория /root/cluster_backup_*)
- [ ] Redis отвечает на PING
- [ ] Redis maxmemory = 8GB
- [ ] Redis requirepass установлен
- [ ] MySQL отвечает на ping
- [ ] MySQL slow_query_log = ON
- [ ] HTTPD запущен (на 10.0.1.200)
- [ ] Скрипты мониторинга в /usr/local/bin/
- [ ] Cron задания настроены
- [ ] Логи пишутся

---

## 📈 МОНИТОРИНГ ПОСЛЕ ИСПРАВЛЕНИЯ

### Запуск скриптов мониторинга вручную:
```bash
# Redis
/usr/local/bin/redis_monitor.sh

# MySQL
/usr/local/bin/mysql_monitor.sh

# Проверка логов мониторинга
tail -100 /var/log/redis/monitoring.log
tail -100 /var/log/mysql/monitoring.log
```

### Проверка cron заданий:
```bash
crontab -l
# Должно быть:
# */5 * * * * /usr/local/bin/redis_monitor.sh
# */5 * * * * /usr/local/bin/mysql_monitor.sh
```

---

## 🎯 ВРЕМЯ ВЫПОЛНЕНИЯ

| Этап | Время |
|------|-------|
| Бэкапы | 2-5 мин |
| Redis исправление | 1-2 мин |
| MySQL исправление | 2-3 мин |
| Мониторинг | 1 мин |
| Проверка | 1-2 мин |
| **ИТОГО** | **~10 мин на сервер** |

---

## ⚠️ ВНИМАНИЕ

1. **Запускайте на каждом сервере отдельно!**
2. **Не прерывайте выполнение скрипта!**
3. **Сохраните директорию с бэкапами!**
4. **Проверьте логи после выполнения!**

---

**ВРЕМЯ ПРИМЕНЕНИЯ:** ~10 минут на сервер
**ПРОСТОЙ:** 5-10 секунд (при перезапуске служб)
**ОТКАТ:** Через бэкапы в /root/cluster_backup_*/
