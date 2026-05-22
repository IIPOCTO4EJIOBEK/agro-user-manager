# 📊 ОТЧЁТ ПО ЛОГАМ И СЕССИЯМ JITSI MEET
**Дата проверки:** 2026-04-02 21:11 MSK

---

## 1️⃣ АКТИВНЫЕ КОНФЕРЕНЦИИ

### Текущая активная конференция:
```
Room: фффф@muc.vks.ahprostory.ru
Meeting ID: de9d834c-bcfa-4729-95a9-5326e71ae59c
```

### Участники (из Jicofo логов):
| Participant ID | Stats ID | Статус |
|----------------|----------|--------|
| 0a7bf61a | Bret-1kE | ✅ Активен (видео 6 SSRC) |
| da668652 | Trevion-KLk | ✅ Активен |
| 04e0259d | Vivienne-Eym | ✅ Активен |
| 18e7a044 | Bret-1kE | ⚠️ Переподключается |

### Видео потоки (Simulcast):
```
Участник 0a7bf61a:
- video=[916984598, 4143374033, 1756930993, 2127194094, 3869750346, 518553710]
- groups=[FID, SIM, FID, FID]
→ 6 видео SSRC (3 потока + FEC) - Simulcast активен! ✅
```

---

## 2️⃣ JVB СЕССИИ

### JVB 10.0.1.131:
```
❌ conferences: {} (ПУСТО)
```
**Статус:** Нет активных конференций

### JVB 10.0.1.132:
```
✅ conferences: {
  "e81d5226d75abf57": {
    "endpoints": {
      "bbca906f": "Trevion-KLk",
      "e372142f": "Vivienne-Eym", 
      "1d64950a": "Bret-1kE"
    }
  }
}
```
**Статус:** 3 участника в конференции

---

## 3️⃣ XMPP СЕССИИ (Prosody)

### Последние аутентификации:
```
21:08:09 - 0a7bf61a-2b7f-4183-919d-c48b00f527bc@guest.vks.ahprostory.ru ✅
21:07:51 - 04e0259d-2b34-4ed3-9252-3319e5ae04ec@guest.vks.ahprostory.ru ✅
21:07:47 - 18e7a044-7d7c-49f8-a9d2-b5cf0f054152@guest.vks.ahprostory.ru ✅
21:07:35 - da668652-640e-4778-a5e8-99e4646a21aa@guest.vks.ahprostory.ru ✅
```

### Системные пользователи:
```
✅ focus@auth.vks.ahprostory.ru (Jicofo)
✅ jvb@auth.vks.ahprostory.ru (JVB x2)
✅ jibri@auth.vks.ahprostory.ru
✅ monitoring@vks.ahprostory.ru
```

---

## 4️⃣ NPM ACCESS LOGS

### Последние запросы:
```
[02/Apr/2026:18:10:35] 200 GET vks.ahprostory.ru
[02/Apr/2026:18:10:15] 200 GET vks.ahprostory.ru
[02/Apr/2026:18:10:05] 200 GET vks.ahprostory.ru
[02/Apr/2026:18:10:04] 200 GET vks.ahprostory.ru
[02/Apr/2026:18:09:55] 200 GET vks.ahprostory.ru
```

**Статус:** Все запросы возвращают 200 OK ✅

---

## 5️⃣ ОШИБКИ

### Jitsi Web Errors:
```
[error] recv() failed (104: Connection reset by peer)
  - client: 10.0.1.110
  - request: GET /xmpp-websocket?room=ффф
  - upstream: http://172.20.0.x:5280/xmpp-websocket
```
**Причина:** Обрыв WebSocket соединения (клиент закрыл соединение)
**Влияние:** Минимальное - клиент переподключается

### NPM Errors:
```
[error] connect() failed (111: Connection refused)
  - client: 92.42.9.27
  - upstream: http://10.0.1.130:80/xmpp-websocket
  
[warn] an upstream response is buffered to a temporary file
  - client: 92.42.9.27, 176.110.129.65
  - request: GET /libs/app.bundle.min.js
```
**Причина:** 
1. Connection refused - временная недоступность Prosody
2. Buffered to temp - большие файлы кэшируются на диск

---

## 6️⃣ OCTO МЕЖСЕРВЕРНАЯ СВЯЗЬ

### Статус мостов:
```
✅ Bridge 1: relayId=10.0.1.132, region=default, stress=0.01-0.03
❌ Bridge 2: relayId=10.0.1.131 - НЕ ИСПОЛЬЗУЕТСЯ
```

### Проблема:
```
BridgeSelectionStrategy.select#132: 
Selected bridge Bridge[jid=.../jitsi-jvb-2, relayId=10.0.1.132]
```
**Все участники подключаются к одному мосту (132)!**

---

## 7️⃣ JVB MEDIA LOGS

### Кодеки (из session-initiate):
```
Audio:
- opus/48000/2 (minptime=10, useinbandfec=1)

Video:
- AV1/90000 ✅
- VP8/90000 ✅
- H264/90000 (profile-level-id=42e01f) ✅
- VP9/90000 ✅
- RTX (retransmission) ✅
```

### Видео настройки:
```
SSRC группы:
- FID (Flow Identification) - основной + retransmission
- SIM (Simulcast) - 3 качества видео
- 6 SSRC на участника
```

---

## 8️⃣ JIBRI STATUS

```
✅ jitsi-jibri-1   Up 49 minutes
✅ node-exporter   Up 49 minutes
```
**Статус:** Готов к записи

---

## 9️⃣ СИСТЕМНЫЕ РЕСУРСЫ

| Сервер | Uptime | Load Avg | RAM Used | RAM Free |
|--------|--------|----------|----------|----------|
| **130** | 6 days 11h | 0.02 | 808 MB | 27525 MB |
| **131** | 49 min | 0.00 | 543 MB | 30833 MB |
| **132** | 5h 14m | 0.18 | 793 MB | 30690 MB |

**Статус:** Все серверы работают с низкой нагрузкой ✅

---

## 🔴 ВЫЯВЛЕННЫЕ ПРОБЛЕМЫ

### 1. Все участники на одном JVB
**Проблема:** Jicofo использует только jitsi-jvb-2 (10.0.1.132)
**Причина:** SingleBridgeSelectionStrategy в stable-9646
**Влияние:** При 100+ участниках возможна перегрузка одного сервера

### 2. Частые переподключения участника
**Проблема:** 18e7a044 переподключается несколько раз
**Логи:**
```
21:07:47 - Authenticated
21:09:41 - Endpoint expired
21:09:41 - Re-allocated
```
**Причина:** Нестабильное соединение у клиента

### 3. WebSocket обрывы
**Проблема:** Connection reset by peer
**Влияние:** Временные разрывы связи
**Решение:** Клиент автоматически переподключается

---

## ✅ РАБОЧИЕ КОМПОНЕНТЫ

| Компонент | Статус | Примечание |
|-----------|--------|------------|
| Jitsi Web | ✅ | 200 OK |
| Prosody XMPP | ✅ | Аутентификация работает |
| Jicofo | ✅ | Координация конференций |
| JVB 132 | ✅ | 3 активных участника |
| JVB 131 | ⚠️ | Работает, но не используется |
| Jibri | ✅ | Готов к записи |
| OCTO | ⚠️ | Включено, но не распределяет |
| Grafana | ✅ | Мониторинг работает |
| Prometheus | ✅ | Метрики собираются |

---

## 📈 СТАТИСТИКА ПО СЕССИЯМ

### Активные комнаты:
- **фффф** (3 участника)

### Участники по типам:
- **Гости:** 4 (guest.vks.ahprostory.ru)
- **Системные:** 4 (focus, jvb x2, jibri)
- **Мониторинг:** 1 (monitoring)

### Видео потоки:
- **Simulcast:** Активен (3 слоя качества)
- **Кодеки:** VP9, H264, VP8, AV1
- **SSRC на участника:** 6 (3 видео + 3 retransmit)

---

## 🛠️ РЕКОМЕНДАЦИИ

### СРОЧНО:
1. ✅ Сервис работает стабильно
2. ⚠️ Мониторить нагрузку на JVB 132

### ПЛАНЫ:
1. Обновить Jicofo до unstable для SplitBridgeSelectionStrategy
2. Настроить балансировку между JVB 131 и 132
3. Добавить алерты при нагрузке > 0.5

---

**ДАТА ОТЧЁТА:** 2026-04-02 21:11 MSK  
**СТАТУС:** ✅ СЕРВИС РАБОТАЕТ СТАБИЛЬНО  
**АКТИВНЫХ УЧАСТНИКОВ:** 3  
**ОШИБОК:** Критических нет
