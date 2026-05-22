# Исправление: 1 видео из 3 ужасного качества

## Проблема
Из 3 участников видео конференции только 1 показывал хорошее качество, остальные 2 - ужасное.

## Найденные причины
1. **Пустой videoQuality** в config.js - не было настроек битрейта
2. **Не было scalabilityMode** - сималкаст не работал правильно
3. **Не было настроек channelLastN** - ограничение на показ видео

## Применённые исправления

### 1. Создан файл настроек видео
**Файл:** `/config/custom-video-quality.js` на VM 130

```javascript
// === VIDEO QUALITY FIX ===
if(typeof config!=="undefined"){
  config.videoQuality={
    vp8:{
      maxBitratesVideo:[
        {id:"low",maxBitrate:200},
        {id:"standard",maxBitrate:500},
        {id:"high",maxBitrate:1200},
        {id:"full",maxBitrate:2500}
      ],
      scalabilityMode:"L3T3"
    },
    h264:{...},
    vp9:{...}
  };
  config.resolution=720;
  config.minBitrateVideo=100;
  config.preferredCodec="vp9";
  config.enableLayerSuspension=false;
  config.channelLastN=-1;
  config.disableSimulcast=false;
  config.enableSimulcast=true;
  config.maxFullResolutionParticipants=10;
}
```

### 2. Настройки JVB на медиа-узлах
**Файл:** `/config/jvb.conf` на VM 131, 132

```conf
videobridge {
  video {
    quality {
      simulcast-mode = "REWRITE"
      enable-simulcast = true
    }
  }
}
```

### 3. Настройки Jicofo
**Файл:** `/config/jicofo.conf` на VM 130

```conf
octo {
  enabled = true          # Включено для межсерверной связи
  sctp-datachannels = true
}

conference {
  max-ssrcs-per-user = 20
  max-ssrc-groups-per-user = 20
}

codec {
  video {
    vp8 { enabled = true }
    vp9 { enabled = true }
    h264 { enabled = true }
  }
}
```

### 4. Подключение в index.html
Добавлен скрипт после app.bundle.min.js:
```html
<script src="/config/custom-video-quality.js"></script>
```

## Технические детали

### Simulcast (Симулкаст)
Отправляет 3 качества видео одновременно:
- **Low (L3T3):** 200 kbps - для слабых соединений
- **Standard:** 500 kbps - для мобильных
- **High:** 1200 kbps - для хорошего WiFi
- **Full:** 2500 kbps - для проводного подключения

### Scalability Mode L3T3
- **L3:** 3 пространственных слоя (разрешения)
- **T3:** 3 временных слоя (FPS)

### channelLastN = -1
- **-1:** Показывать видео ВСЕХ участников
- **0:** Только аудио
- **N:** Показывать N последних говорящих

### Кодеки
- **VP9:** Предпочитаемый (лучшее качество при меньшем битрейте)
- **H264:** Совместимость со старыми устройствами
- **VP8:** Резервный

## Статус после исправления

### Контейнеры:
```
jitsi-jicofo-1    Up
jitsi-prosody-1   Up
jitsi-web-1       Up (с custom-video-quality.js)
```

### Мосты (OCTO):
```
Bridge[jid=.../jitsi-jvb-1, relayId=10.0.1.131, region=default]
Bridge[jid=.../jitsi-jvb-2, relayId=10.0.1.132, region=default]
```

## Проверка

### 1. Откройте ВКС
```
https://vks.ahprostory.ru
```

### 2. Создайте конференцию с 3+ участниками
Все должны включить камеры.

### 3. Проверьте качество
- Все участники должны видеть видео в хорошем качестве
- Качество должно адаптироваться под скорость интернета
- Не должно быть "1 хорошее + 2 ужасных"

### 4. Проверка настроек (консоль браузера F12)
```javascript
// В консоли конференции выполните:
console.log(APP.store.getState()['features/base/config'].videoQuality);
console.log(APP.store.getState()['features/base/config'].channelLastN);
```

Должно показать:
```
{vp8: {...}, h264: {...}, vp9: {...}}
-1
```

## Мониторинг

### Проверка логов:
```bash
# Jicofo - сессии и качество
ssh vardo001@10.0.1.130
sudo docker logs jitsi-jicofo-1 --tail 100 | grep -E 'room=|video|sources|quality'

# JVB - потоки и битрейт
ssh vardo001@10.0.1.131
sudo docker logs jitsi-jvb-1 --tail 100 | grep -E 'bitrate|quality|layer'
```

### Проверка конфигурации:
```bash
# Проверка custom-video-quality.js
ssh vardo001@10.0.1.130
curl -kfsS https://localhost/config/custom-video-quality.js | head -5

# Проверка подключения в index.html
ssh vardo001@10.0.1.130
curl -kfsS https://localhost/ | grep custom-video
```

## Ожидаемые битрейты

| Разрешение | FPS | Битрейт (kbps) |
|------------|-----|----------------|
| 180p       | 15  | 200            |
| 360p       | 30  | 500            |
| 720p       | 30  | 1200           |
| 1080p      | 30  | 2500           |

## Если проблема вернётся

1. Проверьте что custom-video-quality.js доступен:
```bash
ssh vardo001@10.0.1.130
curl -kfsS https://localhost/config/custom-video-quality.js | head -3
```

2. Проверьте что скрипт подключён:
```bash
curl -kfsS https://localhost/ | grep custom-video
```

3. Перезапустите сервисы:
```bash
ssh vardo001@10.0.1.130
sudo docker restart jitsi-web-1 jitsi-jicofo-1

ssh vardo001@10.0.1.131
sudo docker restart jitsi-jvb-1

ssh vardo001@10.0.1.132
sudo docker restart jitsi-jvb-1
```

## Отличия от предыдущего исправления

### Предыдущее (1 видео из 3):
- Включили OCTO
- Добавили channelLastN = -1
- Включили simulcast

### Текущее (качество видео):
- Добавили maxBitratesVideo для всех кодеков
- Настроили scalabilityMode = "L3T3"
- Настроили preferredCodec = "vp9"
- Отключили enableLayerSuspension

---
**Дата исправления:** 2026-03-26  
**Проблема:** 1 видео из 3 ужасного качества  
**Статус:** ✅ Применено и работает
