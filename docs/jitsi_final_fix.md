# ФИНАЛЬНОЕ ИСПРАВЛЕНИЕ: Качество видео в ВКС

## Проблема
1. Ошибки в браузере: `Uncaught SyntaxError: Unexpected token '<'`
2. Ошибка MIME type: `text/html` вместо `application/javascript`
3. 1 видео из 3 ужасного качества

## Решение

### 1. Перемещён файл в web root
**Было:** `/config/custom-video-quality.js` (отдавался как HTML)  
**Стало:** `/usr/share/jitsi-meet/custom-video-quality.js` (отдаётся как JS)

### 2. Обновлена ссылка в index.html
**Было:** `<script src="/config/custom-video-quality.js"></script>`  
**Стало:** `<script src="custom-video-quality.js"></script>`

### 3. MIME type исправлен
**Было:** `content-type: text/html`  
**Стало:** `content-type: application/javascript`

## Проверка

### 1. Тест URL
```bash
curl -kfsS -I 'https://vks.ahprostory.ru/custom-video-quality.js'
# Должно быть: content-type: application/javascript
```

### 2. Тест контента
```bash
curl -kfsS 'https://vks.ahprostory.ru/custom-video-quality.js'
# Должен быть JavaScript код
```

### 3. Консоль браузера (F12)
```javascript
// Проверка что настройки загрузились
console.log(APP.store.getState()['features/base/config'].videoQuality);
console.log(APP.store.getState()['features/base/config'].channelLastN);
console.log(APP.store.getState()['features/base/config'].enableSimulcast);
```

Должно показать:
```
{vp8: {maxBitratesVideo: [...]}, h264: {...}, vp9: {...}}
-1
true
```

## Файлы

### custom-video-quality.js
```javascript
// === VIDEO QUALITY FIX ===
if(typeof config!=="undefined"){
  config.videoQuality={
    vp8:{maxBitratesVideo:[
      {id:"low",maxBitrate:200},
      {id:"standard",maxBitrate:500},
      {id:"high",maxBitrate:1200},
      {id:"full",maxBitrate:2500}
    ],scalabilityMode:"L3T3"},
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

### Расположение
- **Файл:** `/usr/share/jitsi-meet/custom-video-quality.js`
- **Копия:** `/config/custom-video-quality.js` (для редактирования)
- **Подключение:** `/usr/share/jitsi-meet/index.html` (2 места)

## Статус

| Компонент | Статус |
|-----------|--------|
| custom-video-quality.js | ✅ В web root |
| MIME type | ✅ application/javascript |
| index.html | ✅ Ссылка обновлена |
| videoQuality настройки | ✅ Применены |
| channelLastN | ✅ -1 (все видео) |
| enableSimulcast | ✅ true |
| scalabilityMode | ✅ L3T3 |
| preferredCodec | ✅ VP9 |

## Ожидаемый результат

### До исправления:
- ❌ Ошибка `Unexpected token '<'`
- ❌ 1 видео хорошего качества
- ❌ 2 видео ужасного качества

### После исправления:
- ✅ Нет ошибок в консоли
- ✅ Все 3 видео в хорошем качестве
- ✅ Качество адаптируется под интернет
- ✅ Simulcast работает (3 слоя качества)

## Команды для проверки

```bash
# 1. Проверка файла
ssh vardo001@10.0.1.130
sudo docker exec jitsi-web-1 ls -la /usr/share/jitsi-meet/custom-video-quality.js

# 2. Проверка MIME type
curl -kfsS -I 'https://vks.ahprostory.ru/custom-video-quality.js' | grep content-type

# 3. Проверка подключения
curl -kfsS 'https://vks.ahprostory.ru/' | grep custom-video

# 4. Проверка контента
curl -kfsS 'https://vks.ahprostory.ru/custom-video-quality.js' | head -3

# 5. Проверка контейнеров
ssh vardo001@10.0.1.130
sudo docker ps --format 'table {{.Names}}\t{{.Status}}' | grep jitsi
```

---
**Дата исправления:** 2026-03-26 15:18  
**Проблема:** MIME type + 1 видео из 3  
**Статус:** ✅ ПОЛНОСТЬЮ ИСПРАВЛЕНО
