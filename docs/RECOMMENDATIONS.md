# Рекомендации по отказоустойчивости и мониторингу

## 1. Настройка Failover (Keepalived)

Для автоматического переключения трафика в случае падения PROD сервера рекомендуется использовать **Keepalived** и плавающий (Virtual) IP адрес.

### Установка (на обоих серверах):
`yum install keepalived`

### Конфигурация Master (PROD) - /etc/keepalived/keepalived.conf:
```
vrrp_instance VI_1 {
    state MASTER
    interface eth0          # Ваш сетевой интерфейс
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.1.100       # Ваш плавающий IP
    }
}
```

### Конфигурация Backup (REPLICA) - /etc/keepalived/keepalived.conf:
Измените `state MASTER` на `state BACKUP` и `priority 100` на `priority 90`.

## 2. Мониторинг

Для проекта на 1000 пользователей критически важно отслеживать состояние серверов.

**Рекомендуемый стек:** Zabbix (сервер + агенты).

**Что мониторить:**
1.  **MySQL Replication Lag:** `Seconds_Behind_Master`. Если растет > 0, данные на реплике отстают.
2.  **Дисковое пространство:** Особенно NVMe (БД) и HDD (Бэкапы).
3.  **PHP-FPM:** Количество активных процессов (чтобы не упереться в лимит `pm.max_children`).
4.  **Load Average:** Загрузка CPU.

### Быстрая проверка статуса репликации (команда для cron):
`mysql -e "SHOW SLAVE STATUS\G" | grep "Running: Yes"`
Должно возвращать две строки (IO и SQL потоки).
