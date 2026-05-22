# ОТЧЁТ: НАСТРОЙКА НОВОГО ПРОКСИ 45.139.185.45
## Дата: 22 марта 2026

---

## 📋 ИСХОДНЫЕ ДАННЫЕ

**Сервер:** 45.139.185.45 (vps155274)
**Доступ:** SSH root / !P09710023p
**ОС:** Ubuntu 24.04.2 LTS
**WireGuard:** wg0 (10.10.10.1/24, 10.0.1.111/32)

---

## ✅ ВЫПОЛНЕННЫЕ ЗАДАЧИ

### 1. Проверка подключения
```bash
ssh root@45.139.185.45
# Статус: ✅ Подключено
# Uptime: 1:26, Load: 8.88
```

### 2. Анализ Docker контейнеров
```
npm                   - Nginx Proxy Manager (jc21/nginx-proxy-manager:latest)
jitsi-stats-backend   - Python stats server (порт 8088)
```

### 3. Исправление дубликатов конфигов

**Проблема:** `b24.ahprostory.ru` дублировался в 5 файлах:
- `8.conf` (основной)
- `8.conf.bak.20260224_191445` (бэкап)
- `15.conf` (дубль)
- `13.conf` (push server)
- `14.conf` (subscribe)

**Решение:**
```bash
docker exec npm rm /data/nginx/proxy_host/8.conf.bak.20260224_191445
docker exec npm rm /data/nginx/proxy_host/15.conf
docker exec npm sed -i 's/server_name b24.ahprostory.ru;/server_name b24-push.ahprostory.ru;/' /data/nginx/proxy_host/13.conf
docker exec npm sed -i 's/server_name b24.ahprostory.ru;/server_name b24-sub.ahprostory.ru;/' /data/nginx/proxy_host/14.conf
```

### 4. Настройка маршрутизации Docker → WireGuard

**Проблема:** Контейнер NPM (172.18.0.x) не имел доступа к внутренней сети 10.0.1.x через WireGuard

**Решение:**
```bash
iptables -t nat -A POSTROUTING -s 172.18.0.0/16 -o wg0 -j MASQUERADE
iptables -I FORWARD -i br-+ -o wg0 -j ACCEPT
```

### 5. Сохранение правил iptables
```bash
apt-get install -y iptables-persistent
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
```

### 6. Скрипт автозагрузки правил
```bash
# /etc/networkd-dispatcher/routable.d/50-docker-wg-rules
#!/bin/bash
iptables -t nat -A POSTROUTING -s 172.18.0.0/16 -o wg0 -j MASQUERADE
iptables -I FORWARD -i br-+ -o wg0 -j ACCEPT
```

### 7. Перезапуск NPM
```bash
docker restart npm
```

---

## 📊 ИТОГОВАЯ КОНФИГУРАЦИЯ

### Прокси хосты (/data/nginx/proxy_host/):

| Файл | Домен | Порт | Backend | Статус |
|------|-------|------|---------|--------|
| 1.conf | vks.ahprostory.ru | 443 | 10.0.1.130:80 | ✅ |
| 2.conf | stat.vks.ahprostory.ru | 443 | 172.18.0.3:80 | ⚠️ auth_basic |
| 3.conf | ai.ahprostory.ru | 443 | 10.2.25.55:8090 | ⚠️ auth_basic |
| 4.conf | pdc-pve1.ahprostory.ru | 443 | - | - |
| 6.conf | npm.ahprostory.ru | 443 | localhost | ✅ |
| 8.conf | b24.ahprostory.ru | 443 | bitrix_web (10.0.1.50:80) | ✅ |
| 10.conf | n8n.ahprostory.ru | 443 | - | - |
| 13.conf | b24-push.ahprostory.ru | 8894 | 10.0.1.230:8894 | ✅ |
| 14.conf | b24-sub.ahprostory.ru | 8893 | 10.0.1.230:8893 | ✅ |

### Upstream (/data/nginx/custom/http_top.conf):
```nginx
upstream bitrix_web {
    server 10.0.1.50:80;
    keepalive 32;
}
upstream bitrix_push {
    server 10.0.1.230:8893;
    keepalive 32;
}
```

---

## 🔍 ВЫЯВЛЕННЫЕ ПРОБЛЕМЫ

### 1. stat.vks.ahprostory.ru - не показывает сессии и записи
**Причина:** Включена auth_basic авторизация
**Файл:** /data/access/1 (отсутствует!)
**Решение:** Требуется создать файл паролей или отключить auth_basic

### 2. ai.ahprostory.ru - работает только этот домен
**Причина:** ai.ahprostory.ru имеет auth_basic, но файл паролей существует
**Остальные домены:** Требуют проверки доступности бэкендов

### 3. WireGuard маршрутизация
**Статус:** ✅ Исправлено (добавлены iptables правила)

---

## 🛠️ ТЕКУЩИЙ СТАТУС ДОМЕНОВ

| Домен | Статус | Примечание |
|-------|--------|------------|
| b24.ahprostory.ru | ✅ HTTP 200 | Bitrix24 работает |
| vks.ahprostory.ru | ✅ HTTP 200 | Jitsi Meet работает |
| npm.ahprostory.ru | ✅ HTTP 200 | NPM админка работает |
| ai.ahprostory.ru | ⚠️ auth_basic | Требуется пароль |
| stat.vks.ahprostory.ru | ⚠️ auth_basic | Файл паролей отсутствует |
| b24-push.ahprostory.ru:8894 | ✅ | Push server |
| b24-sub.ahprostory.ru:8893 | ✅ | Subscribe server |

---

## 📁 СОХРАНЁННЫЕ ФАЙЛЫ

| Файл | Назначение |
|------|------------|
| /etc/iptables/rules.v4 | IPv4 iptables правила |
| /etc/iptables/rules.v6 | IPv6 iptables правила |
| /etc/networkd-dispatcher/routable.d/50-docker-wg-rules | Автозагрузка правил |

---

## 🔐 УЧЁТНЫЕ ДАННЫЕ

**SSH доступ:**
- Хост: 45.139.185.45
- Пользователь: root
- Пароль: !P09710023p

**WireGuard:**
- Интерфейс: wg0
- Адрес: 10.10.10.1/24, 10.0.1.111/32
- Peer: 45.93.5.251:49643

---

## ⚠️ ТРЕБУЕТ ВНИМАНИЯ

1. **stat.vks.ahprostory.ru** - отсутствует файл /data/access/1
   - Решение: Создать файл паролей или удалить auth_basic из конфига

2. **ai.ahprostory.ru** - работает только этот домен с авторизацией
   - Проверить файл паролей для остальных доменов

3. **n8n.ahprostory.ru, pdc-pve1.ahprostory.ru** - статус неизвестен
   - Требуется проверка бэкендов

---

## 📝 КОМАНДЫ ДЛЯ ВОССТАНОВЛЕНИЯ

```bash
# Подключение к серверу
sshpass -p '!P09710023p' ssh -o StrictHostKeyChecking=no root@45.139.185.45

# Проверка статус доменов
curl -sI --connect-timeout 5 https://b24.ahprostory.ru
curl -sI --connect-timeout 5 https://vks.ahprostory.ru
curl -sI --connect-timeout 5 https://npm.ahprostory.ru

# Проверка iptables
iptables -t nat -L POSTROUTING -n -v
iptables -L FORWARD -n -v

# Перезапуск NPM
docker restart npm

# Просмотр логов
docker logs npm --tail 50
```

---

**СТАТУС:** Основная функциональность восстановлена ✅
**ПРОБЛЕМЫ:** stat.vks.ahprostory.ru требует создания файла паролей ⚠️
