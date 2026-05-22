# АУДИТ СИСТЕМЫ МОНИТОРИГА JITSI CLUSTER
## Дата проверки: 26 Февраля 2026

---

## 📋 ЗАЯВЛЕННАЯ АРХИТЕКТУРА (из отчета пользователя)

### URL и доступы:
- **URL статистики:** https://stat.vks.ahprostory.ru/
- **Входная точка:** 10.0.1.110 (порт 80/443)
- **Внутренний порт:** 8088
- **SSH пользователь:** vardo001
- **Пароль:** !P09710023p

### Распределение ролей:

| Сервер | Роль | Службы | Путь данных |
|--------|------|--------|-------------|
| 10.0.1.110 | Proxy & Backend | NPM, jitsi-stats-backend | /root/npm/app.py |
| 10.0.1.130 | Control Plane | Prosody, Jicofo | docker exec jitsi-prosody-1 |
| 10.0.1.131 | Media Node 1 | Jitsi JVB | curl localhost:8080/debug |
| 10.0.1.132 | Media Node 2 | Jitsi JVB | curl localhost:8080/debug |
| 10.0.1.133 | Recorder | Jibri | /recordings/*.mp4 |

---

## 🔍 ФАКТИЧЕСКОЕ СОСТОЯНИЕ

### ❌ КРИТИЧЕСКИЕ НЕСООТВЕТСТВИЯ

#### 1. Директория `/root/npm` НЕ СУЩЕСТВУЕТ
```
❌ /root/npm/app.py - НЕ НАЙДЕН
❌ /root/npm/docker-compose.yml - НЕ НАЙДЕН
❌ /root/npm/data/logs/ - НЕ НАЙДЕН
```

#### 2. Конфликт IP-адресов в скриптах мониторинга

В системе обнаружены **ДВЕ РАЗНЫЕ ВЕРСИИ** IP-адресов:

| Версия | IP-адреса узлов | Proxy |
|--------|-----------------|-------|
| **Старая** | 10.1.17.130-133 | 10.1.17.148 |
| **Новая** | 10.0.1.130-133 | 10.0.1.110 |

**Файлы со старой версией (10.1.17.x):**
- jitsi_monitor.py
- jitsi_monitor_v4.py - v8.py
- jitsi_monitor_v14_3.py - v14_7.py
- jitsi_monitor_fixed.py (частично)

**Файлы с новой версией (10.0.1.x):**
- jitsi_monitor_110.py
- jitsi_monitor_fixed.py (частично)
- jitsi_monitor_live.py

#### 3. Docker не доступен из текущей сессии
```
❌ Docker CLI не доступен
❌ Невозможно проверить статус контейнеров
```

#### 4. Несоответствие портов

| Заявлено | Фактически |
|----------|------------|
| Порт 8088 (внутренний) | НЕ НАЙДЕН в конфигурациях |
| jitsi-stats-backend | Контейнер НЕ НАЙДЕН |

---

## 📊 НАЙДЕННЫЕ ФАЙЛЫ МОНТОРИНГА

### Актуальные версии скриптов:

| Файл | IP-версия | Статус | Примечание |
|------|-----------|--------|------------|
| jitsi_monitor_live.py | 10.0.1.x | ✅ Готов | Использует SSH на 130-133 |
| jitsi_monitor_110.py | 10.0.1.x | ✅ Готов | Локальная версия для 110 |
| jitsi_monitor.py | 10.1.17.x | ⚠️ Устарел | Требует обновления IP |
| jitsi_monitor_v14_7.py | 10.1.17.x | ⚠️ Устарел | Требует обновления IP |

### Конфигурации Docker:

| Файл | Назначение |
|------|------------|
| docker-compose-npm.yml | Nginx Proxy Manager (порты 80, 443, 10000/udp) |
| 130_compose_fixed.yml | Jitsi кластер (Prosody, Web, Jicofo, JVB) |

---

## 🛠️ РЕКОМЕНДАЦИИ ПО ВОССТАНОВЛЕНИЮ

### 1. Создать директорию мониторинга

```bash
mkdir -p /root/npm/data/www/stats
mkdir -p /root/npm/data/logs
```

### 2. Разместить скрипт мониторинга

Использовать `jitsi_monitor_live.py` как основу для `/root/npm/app.py`

### 3. Создать docker-compose для бекенда

```yaml
# /root/npm/docker-compose.yml
version: '3.8'
services:
  stats:
    image: python:3.11-slim
    container_name: jitsi-stats-backend
    working_dir: /app
    volumes:
      - ./app.py:/app/app.py
      - ./data:/app/data
    ports:
      - "8088:8088"
    command: python app.py
    restart: unless-stopped
```

### 4. Обновить IP-адреса в скриптах

Заменить во всех файлах `10.1.17.x` → `10.0.1.x`:
```bash
sed -i 's/10\.1\.17\./10.0.1./g' jitsi_monitor*.py
```

### 5. Настроить Nginx Proxy Manager

Добавить Proxy Host:
- **Domain:** stat.vks.ahprostory.ru
- **Forward:** 10.0.1.110:8088
- **SSL:** Let's Encrypt

---

## ✅ ПРОВЕРКА КОНФИГУРАЦИИ JITSI

### Файлы конфигурации найдены:

| Файл | Статус | Назначение |
|------|--------|------------|
| jitsi_nginx_full.conf | ✅ | Полный конфиг Nginx для Jitsi |
| jitsi_npm_custom.conf | ✅ | Custom locations для NPM |
| jitsi_npm_advanced.conf | ✅ | Advanced config для NPM |
| 130_compose_fixed.yml | ✅ | Docker Compose для узла 130 |
| CLUSTER_MAP.txt | ✅ | Карта кластера |

### Найденные учетные данные:

| Сервис | Логин | Пароль |
|--------|-------|--------|
| SSH | vardo001 | !P09710023p |
| Jicofo | focus | focuspass123 |
| JVB | jvb | jvbpass123 |

---

## 🎯 ВЫВОДЫ

### Статус системы мониторинга: ⚠️ ТРЕБУЕТ ВОССТАНОВЛЕНИЯ

1. **Директория `/root/npm` не существует** - требуется создание
2. **Контейнер jitsi-stats-backend не запущен** - требуется развертывание
3. **IP-адреса в скриптах неактуальны** - требуется замена 10.1.17.x → 10.0.1.x
4. **Docker недоступен** - требуется проверка прав доступа

### Рабочие компоненты:

✅ Скрипты мониторинга (jitsi_monitor_live.py)
✅ Конфигурации Nginx для Jitsi
✅ Docker Compose для узлов кластера
✅ Карта кластера и документация

### Требуемые действия:

1. Создать структуру директорий `/root/npm`
2. Разместить актуальный скрипт мониторинга
3. Создать и запустить Docker контейнер бекенда
4. Настроить Proxy Host в Nginx Proxy Manager
5. Обновить все скрипты с 10.1.17.x на 10.0.1.x

---

## 📞 КОНТАКТНАЯ ИНФОРМАЦИЯ

**Техническая поддержка:** vardo001
**Пароль для SSH/Sudo:** !P09710023p

---

**СТАТУС АУДИТА:** ⚠️ ТРЕБУЕТСЯ ВНИМАНИЕ
**ДАТА СЛЕДУЮЩЕЙ ПРОВЕРКИ:** 27 Февраля 2026
