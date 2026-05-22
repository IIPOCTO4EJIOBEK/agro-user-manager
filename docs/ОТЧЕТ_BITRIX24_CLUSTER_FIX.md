# ОТЧЕТ ПО ИСПРАВЛЕНИЮ BITRIX24 CLUSTER UNIQUE ID ERROR

## Дата выполнения
24 февраля 2026

## Проблема
При проверке сайта через `site_checker.php` возникала ошибка:
```
Permission denied: UNIQUE ID ERROR
```

## Архитектура кластера
```
10.0.1.110 (Nginx Proxy) → 10.0.1.50 (HAProxy) → 10.0.1.220/221/222 (Nginx → Apache:8888) → Bitrix24
```

### Сервера
- **10.0.1.110** - внешний прокси (Nginx Proxy Manager)
- **10.0.1.50** - балансировщик кластера (HAProxy)
- **10.0.1.220** (b24-web-01) - веб-узел кластера
- **10.0.1.221** (b24-web-02) - веб-узел кластера
- **10.0.1.222** (b24-web-03) - веб-узел кластера
- **10.0.1.200** - мастер Ansible
- **10.0.1.201** - реплика БД
- **10.0.1.210** - Redis
- **10.0.1.230** - Push server

## Найденные проблемы

### 1. Рассинхронизация файла license_key.php
Файл `/home/bitrix/www/bitrix/license_key.php` имел разное содержимое на узлах:
- **10.0.1.220, 10.0.1.221**: `<? $LICENSE_KEY = "P25-ML-PLBNQN7UM28BGK5XQMSI"; ?>` (51 байт)
- **10.0.1.222**: `<?$LICENSE_KEY = "P25-ML-PLBNQN7UM28BGK5XQMSI";?>` (49 байт)

Разница в пробелах приводила к разному `unique_id`.

### 2. Кэш OPcache
PHP OPcache кэшировал старые версии файлов, что приводило к некорректной работе функции `checker_get_unique_id()`.

## Выполненные действия

### 1. Синхронизация license_key.php
```bash
# На всех узлах (10.0.1.220, 221, 222) выполнен скрипт:
cat > /home/bitrix/www/bitrix/license_key.php << 'EOF'
<? $LICENSE_KEY = "P25-ML-PLBNQN7UM28BGK5XQMSI"; ?>
EOF
chown bitrix:bitrix /home/bitrix/www/bitrix/license_key.php
chmod 644 /home/bitrix/www/bitrix/license_key.php
```

### 2. Очистка OPcache
```bash
# На всех узлах:
rm -rf /var/lib/php/opcache/*
systemctl restart httpd
```

### 3. Обновление конфигурации HAProxy
Обновлен `/etc/haproxy/haproxy.cfg` на 10.0.1.50:
- Добавлена опция `option redispatch 0` (не переключать сессию на другой сервер)
- Добавлены health checks
- Добавлены retries
- Настроены cookie для sticky sessions

### 4. Перезапуск служб
```bash
# HAProxy
systemctl restart haproxy

# Apache на всех узлах
systemctl restart httpd
```

## Проверка результата

### Проверка unique_id на всех узлах
```bash
# Все узлы теперь возвращают одинаковый unique_id:
# 62fb7541a66bfefc12c9e9c0724b4b7b59b3674bbf179f96d9da33f4e15eab4f
```

### Тест site_checker.php
```bash
# Тест redirect_test:
curl -k -L 'https://b24.ahprostory.ru/bitrix/admin/site_checker.php?test_type=redirect_test&unique_id=62fb7541a66bfefc12c9e9c0724b4b7b59b3674bbf179f96d9da33f4e15eab4f&SERVER_PORT=443&HTTPS=on&done=Y'
# Результат: SUCCESS
```

### Проверка sticky sessions
5 последовательных запросов возвращают SUCCESS, sticky sessions работают корректно.

## Файлы, созданные в процессе исправления

| Файл | Описание |
|------|----------|
| `/root/haproxy_bitrix24_fixed.cfg` | Исправленная конфигурация HAProxy |
| `/root/99-proxy.conf.bitrix24_fixed` | Исправленная конфигурация Nginx (резервная) |
| `/root/bitrix24_cluster_check.sh` | Скрипт проверки кластера |
| `/root/bitrix24_cluster_deploy.sh` | Скрипт развертывания конфигурации |
| `/root/BITRIX24_CLUSTER_FIX.md` | Документация |

## Рекомендации

### 1. Настроить синхронизацию конфигурации
Использовать Ansible для синхронизации файлов конфигурации между узлами:
- `/home/bitrix/www/bitrix/license_key.php`
- `/home/bitrix/www/bitrix/.settings.php`
- `/home/bitrix/www/bitrix/.settings_extra.php`

### 2. Настроить общий кэш сессий
Включить сохранение сессий в Redis или Memcached для всех узлов кластера.

### 3. Настроить мониторинг
Добавить проверку unique_id на всех узлах в систему мониторинга.

### 4. Настроить sudo без пароля
Для автоматизации развертывания настроить sudo без пароля для пользователя vardo001.

## SSH доступ
- **Username:** vardo001 / root
- **Password:** !P09710023p
- **Port:** 22

## Контакты
Исправление выполнено автоматически системой управления кластером.
