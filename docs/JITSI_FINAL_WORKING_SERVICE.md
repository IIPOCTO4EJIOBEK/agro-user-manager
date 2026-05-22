# ✅ JITSI MEET CLUSTER - ГОТОВЫЙ РАБОЧИЙ СЕРВИС

**Дата:** 2026-04-02  
**Статус:** ✅ РАБОЧИЙ СЕРВИС  
**URL:** https://vks.ahprostory.ru

---

## 📊 АРХИТЕКТУРА

```
                    Интернет (185.160.36.97)
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  10.0.1.110 (Nginx Proxy Manager)       │
        │  - NAT: 10000/udp → 10.0.1.131:10000    │
        │  - NAT: 10001/udp → 10.0.1.132:10000    │
        │  - HTTPS: 443 → 10.0.1.130:443          │
        └────────────────┬────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│  10.0.1.130   │ │  10.0.1.131   │ │  10.0.1.132   │
│  jitsi-main   │ │  jitsi-jvb-1  │ │  jitsi-jvb-2  │
├───────────────┤ ├───────────────┤ ├───────────────┤
│ Prosody XMPP  │ │ JVB (Video)   │ │ JVB (Video)   │
│ Jicofo        │ │ OCTO: enabled │ │ OCTO: enabled │
│ Web           │ │ UDP:10000     │ │ UDP:10000     │
│ Grafana:3000  │ │               │ │               │
│ Prometheus    │ │               │ │               │
└───────────────┘ └───────────────┘ └───────────────┘
         │
         ▼
┌───────────────┐
│  10.0.1.133   │
│  jitsi-jibri  │
├───────────────┤
│ Recording     │
│ 500GB HDD     │
└───────────────┘
```

---

## ✅ РАБОЧИЕ КОМПОНЕНТЫ

| Компонент | Статус | Порт | URL/IP |
|-----------|--------|------|--------|
| **Jitsi Meet Web** | 🟢 Online | 443 | https://vks.ahprostory.ru |
| **Prosody XMPP** | 🟢 Online | 5222, 5280 | 10.0.1.130 |
| **Jicofo** | 🟢 Online | 8888 | 10.0.1.130 |
| **JVB #1** | 🟢 Online | 10000/udp | 10.0.1.131 |
| **JVB #2** | 🟢 Online | 10000/udp | 10.0.1.132 |
| **Grafana** | 🟢 Online | 3000 | http://10.0.1.130:3000 |
| **Prometheus** | 🟢 Online | 9090 | http://10.0.1.130:9090 |
| **Jibri** | 🟢 Online | - | 10.0.1.133 |

---

## 🔑 ДОСТУПЫ

### SSH доступ к серверам:
```
VM 130 (main):   ssh vardo001@10.0.1.130  пароль: !P09710023p
VM 131 (jvb-1):  ssh vardo001@10.0.1.131  пароль: !P09710023p
VM 132 (jvb-2):  ssh vardo001@10.0.1.132  пароль: !P09710023p
VM 133 (jibri):  ssh vardo001@10.0.1.133  пароль: !P09710023p
Proxy 110:       ssh vardo001@10.0.1.110  пароль: !P09710023p
```

### Jitsi Meet пользователи:
```
Admin:      login: admin      пароль: @groAdm54
Monitoring: login: monitoring пароль: Company2024!
```

### Grafana:
```
login: admin
пароль: Gr4fana2026!
```

---

## 🧪 ТЕСТИРОВАНИЕ

### 1. Проверка веб-доступа
```bash
curl -kfsS 'https://vks.ahprostory.ru/' | grep -i 'Jitsi Meet'
```

### 2. Проверка контейнеров
```bash
ssh vardo001@10.0.1.130
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep jitsi
```

### 3. Проверка мостов JVB
```bash
ssh vardo001@10.0.1.130
docker logs jitsi-jicofo-1 2>&1 | grep 'Bridge\[.*relayId'
```

### 4. Проверка JVB API
```bash
# JVB 131
ssh vardo001@10.0.1.131
curl -s http://localhost:8080/debug | python3 -m json.tool

# JVB 132
ssh vardo001@10.0.1.132
curl -s http://localhost:8080/debug | python3 -m json.tool
```

### 5. Тест конференции
1. Откройте https://vks.ahprostory.ru
2. Создайте комнату: `testroom123`
3. Подключите 2+ участников с разных устройств
4. Включите камеры и микрофоны
5. Все участники должны видеть и слышать друг друга

---

## 📋 КОНФИГУРАЦИЯ

### docker-compose.yml (основные параметры):
```yaml
jicofo:
  image: jitsi/jicofo:stable-9646
  environment:
    - ENABLE_OCTO=true
    - JICOFO_ENABLE_OCTO=true
    - BRIDGE_SELECTION_STRATEGY=SplitBridgeSelectionStrategy
    - JICOFO_MAX_PARTICIPANTS_PER_CONFERENCE=100
    - JVB_STRESS_THRESHOLD=0.5

jvb (на 131 и 132):
  image: jitsi/jvb:stable-9646
  environment:
    - ENABLE_OCTO=1
    - JVB_OCTO_PUBLIC_ADDRESS=10.0.1.131 (или 132)
    - JVB_OCTO_BIND_ADDRESS=10.0.1.131 (или 132)
    - JVB_ADVERTISED_IPS=185.160.36.97
    - JVB_PORT=10000
```

### OCTO настройки:
```
✅ OCTO включен (enabled = true)
✅ Оба JVB имеют relayId
✅ Регион: default
✅ SCTP datachannels: enabled
```

---

## 🔧 УПРАВЛЕНИЕ

### Перезапуск сервисов:
```bash
# Все сервисы
ssh vardo001@10.0.1.130
docker compose -f /root/jitsi/docker-compose.yml restart

# Отдельный сервис
docker compose -f /root/jitsi/docker-compose.yml restart jicofo
```

### Просмотр логов:
```bash
# Jicofo
docker logs jitsi-jicofo-1 --tail 100 -f

# JVB
ssh vardo001@10.0.1.131
docker logs jitsi-jvb-1 --tail 100 -f
```

### Остановка сервиса:
```bash
ssh vardo001@10.0.1.130
docker compose -f /root/jitsi/docker-compose.yml down
```

### Запуск сервиса:
```bash
ssh vardo001@10.0.1.130
docker compose -f /root/jitsi/docker-compose.yml up -d
```

---

## 📈 МОНИТОРИНГ

### Grafana Dashboard:
- URL: http://10.0.1.130:3000
- Логин: admin / Gr4fana2026!

### Prometheus Metrics:
- URL: http://10.0.1.130:9090
- JVB Metrics: http://10.0.1.131:8080/metrics

### Node Exporter:
- Порт: 9100 на всех серверах
- URL: http://10.0.1.130:9100/metrics

---

## ⚠️ ИЗВЕСТНЫЕ ОГРАНИЧЕНИЯ

### 1. Стратегия выбора моста
Jicofo stable-9646 использует `SingleBridgeSelectionStrategy` по умолчанию.
Все участники конференции подключаются к одному JVB.

**Решение для будущего:**
```bash
# Обновить до Jicofo unstable/latest
docker pull jitsi/jicofo:unstable
# Переменная BRIDGE_SELECTION_STRATEGY=SplitBridgeSelectionStrategy
# начнет работать в новых версиях
```

### 2. Лимиты JVB
При 100+ участниках в одной конференции может потребоваться:
- Увеличить `JICOFO_MAX_PARTICIPANTS_PER_CONFERENCE`
- Добавить больше JVB узлов
- Настроить `JVB_STRESS_THRESHOLD`

---

## 🆘 УСТРАНЕНИЕ НЕИСПРАВНОСТЕЙ

### Проблема: Видно только себя
**Решение:**
```bash
# 1. Проверить что Jicofo видит оба моста
ssh vardo001@10.0.1.130
docker logs jitsi-jicofo-1 | grep 'Bridge\[.*relayId'

# 2. Проверить что UDP 10000 открыт
for ip in 10.0.1.131 10.0.1.132; do
  nc -zvu $ip 10000 && echo "$ip:10000 OPEN" || echo "$ip:10000 CLOSED"
done

# 3. Перезапустить JVB
ssh vardo001@10.0.1.131 && docker restart jitsi-jvb-1
ssh vardo001@10.0.1.132 && docker restart jitsi-jvb-1
```

### Проблема: Не работает HTTPS
**Решение:**
```bash
# Проверить NPM
ssh vardo001@10.0.1.110
docker logs npm --tail 50

# Проверить сертификат
docker exec npm cat /etc/letsencrypt/live/npm-*/fullchain.pem | openssl x509 -noout -dates
```

### Проблема: Jicofo перезапускается
**Решение:**
```bash
# Посмотреть логи
docker logs jitsi-jicofo-1 --tail 100

# Проверить конфиг
docker exec jitsi-jicofo-1 cat /config/jicofo.conf | head -30

# Пересоздать контейнер
docker compose up -d --force-recreate jicofo
```

---

## 📝 ИСТОРИЯ ИЗМЕНЕНИЙ

### 2026-04-02
- ✅ Включен OCTO (ENABLE_OCTO=true)
- ✅ Добавлены переменные для SplitBridgeSelectionStrategy
- ✅ Настроены JVB с OCTO (relayId=10.0.1.131,132)
- ✅ Открыты UDP порты 10000 на брандмауэрах
- ✅ Все контейнеры работают стабильно

---

## 📞 ПОДДЕРЖКА

**Администратор:** vardo001  
**Пароль SSH:** !P09710023p  
**Серверы:** 10.0.1.130-133, 10.0.1.110

---

**ДАТА:** 2026-04-02  
**СТАТУС:** ✅ СЕРВИС ГОТОВ К РАБОТЕ  
**ПОРТАЛ:** https://vks.ahprostory.ru
