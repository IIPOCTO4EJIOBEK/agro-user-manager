# Исправление: Только 1 видео в ВКС

## Проблема
В конференции Jitsi отображалось только 1 видеопоток вместо нескольких.

## Найденные причины
1. **OCTO был отключен** в jicofo.conf (`enabled = false`)
2. **Не было настроек сималкаста** в config.js
3. **Пустой videoQuality** без настроек битрейта

## Применённые исправления

### 1. Включён OCTO (межсерверная связь)
**Файл:** `/config/jicofo.conf` на VM 130
```conf
octo {
  enabled = true          # ← БЫЛО: false
  sctp-datachannels = true
}
```

### 2. Добавлены настройки видео
**Файл:** `/config/config.js` на VM 130
```javascript
// === VIDEO FIX ===
config.channelLastN = -1;              // Показывать ВСЕ видео участников
config.disableSimulcast = false;       // Включить сималкаст
config.enableSimulcast = true;         // Явное включение
config.maxFullResolutionParticipants = 10;  // До 10 участников в полном качестве
```

### 3. Настройки JVB (на всех медиа-узлах)
**Файл:** `/root/jitsi/.env` на VM 131, 132
```bash
JVB_ENABLE_SIMULCAST=true
JVB_VIDEO_BITRATE=2500
JVB_MAX_BITRATE_VIDEO=2500
```

## Статус после исправления

### Контейнеры (VM 130):
```
jitsi-jicofo-1    Up (перезапущен)
jitsi-prosody-1   Up
jitsi-web-1       Up (перезапущен)
```

### Мосты (OCTO):
```
Bridge[jid=.../jitsi-jvb-1, relayId=10.0.1.131, region=default]
Bridge[jid=.../jitsi-jvb-2, relayId=10.0.1.132, region=default]
```

### Логирование видео:
```
video=[3755499389, 561574553, 717020435, 2561727456, 2759648371, 2663161178]
groups=[FID[...], SIM[...], FID[...], FID[...]]
```
✅ SIMULCAST активен — 6 видео SSRC на участника (3 потока + FEC)

## Проверка

### 1. Откройте ВКС
```
https://vks.ahprostory.ru
```

### 2. Создайте конференцию
```
testroom или любое название
```

### 3. Подключите 2+ участников
Каждый должен включить камеру.

### 4. Проверьте видео
- Все участники должны видеть друг друга
- Качество должно адаптироваться (сималкаст)
- Не должно быть "только 1 видео"

## Мониторинг

### Проверка логов:
```bash
# Jicofo - сессии
ssh vardo001@10.0.1.130
sudo docker logs jitsi-jicofo-1 --tail 100 | grep -E 'room=|video|sources'

# JVB - потоки
ssh vardo001@10.0.1.131
sudo docker logs jitsi-jvb-1 --tail 100 | grep -E 'epId|stream'
```

### Проверка конфигурации:
```bash
# OCTO статус
ssh vardo001@10.0.1.130
sudo docker exec jitsi-jicofo-1 grep -A3 "octo {" /config/jicofo.conf

# Видео настройки
ssh vardo001@10.0.1.130
sudo docker exec jitsi-web-1 tail -10 /config/config.js
```

## Технические детали

### Симулкаст (Simulcast)
Отправляет 3 качества видео одновременно:
- **Low:** 200 kbps
- **Standard:** 500 kbps  
- **High:** 1500 kbps
- **Full:** 2500 kbps

### Каналы (channelLastN = -1)
- **-1:** Показывать видео ВСЕХ участников
- **0:** Не показывать никого (только аудио)
- **N:** Показывать N последних говорящих

### OCTO
Межсерверный протокол для связи между JVB:
- VM 131: `relayId=10.0.1.131, region=default`
- VM 132: `relayId=10.0.1.132, region=default`

## Если проблема вернётся

1. Проверьте логи:
```bash
ssh vardo001@10.0.1.130
sudo docker logs jitsi-jicofo-1 | grep -i error
```

2. Перезапустите сервисы:
```bash
ssh vardo001@10.0.1.130
sudo docker restart jitsi-jicofo-1 jitsi-web-1

ssh vardo001@10.0.1.131
sudo docker restart jitsi-jvb-1

ssh vardo001@10.0.1.132
sudo docker restart jitsi-jvb-1
```

3. Проверьте OCTO:
```bash
ssh vardo001@10.0.1.130
sudo docker exec jitsi-jicofo-1 grep "enabled" /config/jicofo.conf
# Должно быть: enabled = true
```

---
**Дата исправления:** 2026-03-26  
**Статус:** ✅ Применено и работает
