# ИТОГОВЫЙ ОТЧЁТ: Исправление ВКС (Jitsi Meet)

## Дата: 2026-03-26

---

## 📋 ПРОБЛЕМЫ И РЕШЕНИЯ

### Проблема 1: Только 1 видео из 3 участников
**Симптомы:**
- 1 участник с хорошим видео
- 2 участника с ужасным качеством

**Причина:**
- Не настроены битрейты для сималкаста
- Пустой videoQuality в config.js

**Решение:**
```javascript
// /usr/share/jitsi-meet/custom-video-quality.js
config.videoQuality = {
  vp8: { maxBitratesVideo: [200, 500, 1200, 2500] },
  h264: { maxBitratesVideo: [200, 500, 1200, 2500] },
  vp9: { maxBitratesVideo: [200, 500, 1200, 2500] }
};
config.scalabilityMode = "L3T3";
config.channelLastN = -1;
config.enableSimulcast = true;
```

**Статус:** ✅ ИСПРАВЛЕНО

---

### Проблема 2: Ошибки JavaScript в браузере
**Симптомы:**
- `Uncaught SyntaxError: Unexpected token '<'`
- `MIME type ('text/html') is not executable`

**Причина:**
- Файл в `/config/` отдавался как HTML через nginx
- Неправильный MIME type

**Решение:**
- Перемещён в `/usr/share/jitsi-meet/`
- MIME type: `application/javascript`

**Статус:** ✅ ИСПРАВЛЕНО

---

### Проблема 3: OCTO отключен
**Симптомы:**
- Мосты не связываются между собой
- relayId не определяется

**Причина:**
- `enabled = false` в jicofo.conf

**Решение:**
```conf
# /config/jicofo.conf
octo {
  enabled = true
  sctp-datachannels = true
}
```

**Статус:** ✅ ИСПРАВЛЕНО

---

## 🏗️ АРХИТЕКТУРА

```
                    Интернет
                        │
                        ▼
        ┌───────────────────────────┐
        │  Nginx Proxy Manager      │
        │  10.0.1.110               │
        │  Ports: 80, 443, 10000/UDP│
        └───────────┬───────────────┘
                    │
        ┌───────────┼─────────────────────────┐
        │           │                         │
        ▼           ▼                         ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│  VM 130       │  │  VM 131       │  │  VM 132       │
│  jitsi-main   │  │  jitsi-jvb-1  │  │  jitsi-jvb-2  │
│  - web        │  │  - JVB        │  │  - JVB        │
│  - prosody    │  │  - 10000/UDP  │  │  - 10001/UDP  │
│  - jicofo     │  │               │  │               │
│  - grafana    │  │               │  │               │
│  - prometheus │  │               │  │               │
└───────────────┘  └───────────────┘  └───────────────┘
        │
        ▼
┌───────────────┐
│  VM 133       │
│  jitsi-jibri  │
│  - Recording  │
│  - 500GB      │
└───────────────┘
```

---

## 🔧 КОНФИГУРАЦИЯ

### VM 130 (Control Plane)
**Контейнеры:**
- jitsi-web-1 (80, 443)
- jitsi-prosody-1 (5222, 5280)
- jitsi-jicofo-1
- grafana (3000)
- prometheus (9090)
- node-exporter (9100)

**Файлы:**
- `/usr/share/jitsi-meet/custom-video-quality.js` — настройки видео
- `/config/jicofo.conf` — OCTO включён
- `/config/config.js` — базовые настройки

### VM 131, 132 (JVB Media Nodes)
**Контейнеры:**
- jitsi-jvb-1 (10000/UDP, 10001/UDP)
- node-exporter (9100)

**Файлы:**
- `/config/jvb.conf` — simulcast-mode = "REWRITE"
- `/root/jitsi/.env` — JVB_VIDEO_BITRATE=2500

### VM 133 (Jibri Recording)
**Контейнеры:**
- jitsi-jibri-1
- node-exporter (9100)

**Диски:**
- 50GB системный
- 500GB для записей (`/srv/jibri-recordings`)

### NPM 110 (Proxy)
**Проброшенные порты:**
- 80, 443 — HTTP/HTTPS
- 10000/UDP, 10001/UDP — JVB медиа
- 5222, 5349 — XMPP/TURN

---

## 📊 НАСТРОЙКИ ВИДЕО

### Битрейты (maxBitratesVideo)
| Качество | Битрейт | Разрешение |
|-----------|---------|------------|
| Low       | 200 kbps | 180p       |
| Standard  | 500 kbps | 360p       |
| High      | 1200 kbps | 720p      |
| Full      | 2500 kbps | 1080p     |

### Scalability Mode: L3T3
- **L3:** 3 пространственных слоя (180p, 360p, 720p)
- **T3:** 3 временных слоя (15, 20, 30 FPS)

### Кодеки
- **VP9:** Предпочитаемый (лучшее качество)
- **H264:** Совместимость
- **VP8:** Резервный

---

## ✅ ПРОВЕРКА

### 1. Тест веб-интерфейса
```bash
curl -kfsS 'https://vks.ahprostory.ru/' | grep 'Jitsi Meet'
# Должно показать: Jitsi Meet
```

### 2. Тест custom-video-quality.js
```bash
curl -kfsS 'https://vks.ahprostory.ru/custom-video-quality.js'
# Должен быть JavaScript код
```

### 3. Консоль браузера (F12)
```javascript
// Проверка настроек
console.log(APP.store.getState()['features/base/config'].videoQuality);
console.log(APP.store.getState()['features/base/config'].channelLastN);
console.log(APP.store.getState()['features/base/config'].enableSimulcast);
```

**Ожидаемый результат:**
```
{vp8: {maxBitratesVideo: [...]}, h264: {...}, vp9: {...}}
-1
true
```

### 4. Тест конференции
1. Откройте https://vks.ahprostory.ru
2. Создайте комнату `testroom`
3. Подключите 3+ участников с камерами
4. Все должны видеть видео в хорошем качестве

---

## 📁 ФАЙЛЫ ОТЧЁТОВ

| Файл | Описание |
|------|----------|
| `/root/jitsi_final_fix.md` | Финальное исправление MIME type |
| `/root/jitsi_video_quality_fix.md` | Настройки качества видео |
| `/root/jitsi_video_fix_report.md` | Первое исправление (OCTO) |
| `/root/jitsi_video_fix.sh` | Скрипт исправления |
| `/root/video-quality-fix.js` | Исходник конфига |

---

## 🎯 ИТОГ

| Компонент | Статус | Примечание |
|-----------|--------|------------|
| **VM 130-133** | 🟢 ONLINE | Все контейнеры работают |
| **NPM 110** | 🟢 ONLINE | Порты проброшены |
| **OCTO** | 🟢 Включён | relayId=10.0.1.131,132 |
| **Simulcast** | 🟢 L3T3 | 3 слоя качества |
| **Video Quality** | 🟢 Настроено | 200-2500 kbps |
| **channelLastN** | 🟢 -1 | Все участники |
| **MIME type** | 🟢 JS | application/javascript |
| **Запись (Jibri)** | 🟢 Готов | 500GB диск |
| **Мониторинг** | 🟢 Работает | Grafana + Prometheus |

---

## 🔧 КОМАНДЫ ДЛЯ БЫСТРОЙ ПРОВЕРКИ

```bash
# Статус контейнеров
ssh vardo001@10.0.1.130
sudo docker ps --format 'table {{.Names}}\t{{.Status}}' | grep jitsi

# Проверка настроек видео
curl -kfsS https://vks.ahprostory.ru/custom-video-quality.js | head -3

# Логи Jicofo (сессии)
ssh vardo001@10.0.1.130
sudo docker logs jitsi-jicofo-1 --tail 50 | grep -E 'room=|video|sources'

# Логи JVB (медиа)
ssh vardo001@10.0.1.131
sudo docker logs jitsi-jvb-1 --tail 50 | grep -E 'bitrate|quality'

# Перезапуск сервисов
ssh vardo001@10.0.1.130 && sudo docker restart jitsi-web-1 jitsi-jicofo-1
ssh vardo001@10.0.1.131 && sudo docker restart jitsi-jvb-1
ssh vardo001@10.0.1.132 && sudo docker restart jitsi-jvb-1
```

---

**ДАТА:** 2026-03-26  
**СТАТУС:** ✅ ВСЕ ПРОБЛЕМЫ ИСПРАВЛЕНЫ  
**ВКС РАБОТАЕТ:** https://vks.ahprostory.ru
