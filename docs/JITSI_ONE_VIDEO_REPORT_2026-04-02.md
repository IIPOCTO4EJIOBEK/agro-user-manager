# 🔧 ОТЧЁТ: Проблема "1 видео" в Jitsi Meet

**Дата:** 2026-04-02  
**Статус:** ⚠️ ЧАСТИЧНО ИСПРАВЛЕНО (OCTO включен, но стратегия не работает)

---

## 🔴 ПРОБЛЕМА

В конференции видно только 1 видео из нескольких участников.

---

## 🔍 ДИАГНОСТИКА

### 1. OCTO был выключен ✅ ИСПРАВЛЕНО
**Причина:** В docker-compose.yml отсутствовала переменная `ENABLE_OCTO`

**Исправление:**
```yaml
jicofo:
  environment:
    - ENABLE_OCTO=true
    - JICOFO_ENABLE_OCTO=true
```

**Результат:** OCTO теперь включен (`enabled = true`)

### 2. SingleBridgeSelectionStrategy ⚠️ НЕ ИСПРАВЛЕНО

**Проблема:** Jicofo использует `SingleBridgeSelectionStrategy` которая выбирает только ОДИН мост для всех участников конференции.

**Логи:**
```
Jicofo INFO: Using org.jitsi.jicofo.bridge.SingleBridgeSelectionStrategy
Jicofo INFO: Selected bridge Bridge[jid=.../jitsi-jvb-2, relayId=10.0.1.132]
```

**Результат:**
- JVB 10.0.1.131: `conferences:{}` (ПУСТО)
- JVB 10.0.1.132: `conferences:{...2 конференции...}` (ВСЕ ТУТ)

Все участники подключаются к одному JVB (132), поэтому при превышении лимитов видео начинает "пропадать".

---

## 📊 ТЕКУЩАЯ АРХИТЕКТУРА

```
                    Интернет
                        │
                        ▼
        ┌───────────────────────────┐
        │  NPM 10.0.1.110           │
        │  NAT: 10000→131, 10001→132│
        └───────────┬───────────────┘
                    │
         ┌──────────┼──────────┐
         ▼                     ▼
┌─────────────────┐   ┌─────────────────┐
│  10.0.1.131     │   │  10.0.1.132     │
│  JVB #1         │   │  JVB #2         │
│  relayId=131    │   │  relayId=132    │
│  conferences: 0 │   │  conferences: 2 │ ← ВСЕ ТУТ
│  endpoints: 0   │   │  endpoints: 4   │
└─────────────────┘   └─────────────────┘
         ▲                     ▲
         └──────────┬──────────┘
                    │
            ┌───────────────┐
            │  Jicofo       │
            │  SingleBridge │ ← ПРОБЛЕМА
            │  Selection    │
            └───────────────┘
```

---

## 🛠️ ПОПЫТКИ ИСПРАВЛЕНИЯ

### 1. Добавление ENABLE_OCTO ✅
```bash
docker-compose.yml:
  - ENABLE_OCTO=true
  - JICOFO_ENABLE_OCTO=true
```
**Результат:** OCTO включен, мосты видны в Jicofo

### 2. Попытка изменить стратегию ❌
```bash
# Не работает в stable-9646
- BRIDGE_SELECTION_STRATEGY=SplitBridgeSelectionStrategy
- JICOFO_BRIDGE_SELECTION_STRATEGY=SplitBridgeSelectionStrategy
```
**Результат:** Jicofo игнорирует переменные

### 3. Прямое редактирование jicofo.conf ❌
```bash
bridge {
  selection-strategy = "org.jitsi.jicofo.bridge.SplitBridgeSelectionStrategy"
}
```
**Результат:** Конфигурация перезаписывается при запуске контейнера

---

## 💡 РЕШЕНИЯ

### Вариант 1: Обновить Jicofo до последней версии
Новые версии Jicofo поддерживают переменную окружения:
```yaml
jicofo:
  image: jitsi/jicofo:latest  # или unstable
  environment:
    - BRIDGE_SELECTION_STRATEGY=SplitBridgeSelectionStrategy
```

### Вариант 2: Использовать volume с конфигом
```yaml
jicofo:
  volumes:
    - ./jicofo.conf:/config/jicofo.conf:ro
```

**Содержимое jicofo.conf:**
```conf
jicofo {
  bridge {
    selection-strategy = "org.jitsi.jicofo.bridge.SplitBridgeSelectionStrategy"
  }
}
```

### Вариант 3: Временное решение - увеличить лимиты
Если проблема в лимитах JVB, можно увеличить параметры:
```yaml
environment:
  - JICOFO_MAX_PARTICIPANTS_PER_CONFERENCE=200
  - JVB_STRESS_THRESHOLD=0.8
```

---

## ✅ ЧТО РАБОТАЕТ

| Компонент | Статус |
|-----------|--------|
| OCTO включен | ✅ |
| Мосты видны | ✅ (2 моста с relayId) |
| JVB 131 онлайн | ✅ |
| JVB 132 онлайн | ✅ |
| HTTPS доступ | ✅ |
| XMPP подключение | ✅ |

---

## ⚠️ ЧТО НЕ РАБОТАЕТ

| Компонент | Проблема |
|-----------|----------|
| SplitBridgeSelectionStrategy | ❌ Не применяется |
| Распределение участников | ❌ Все на одном JVB |
| OCTO межсерверная связь | ⚠️ Работает, но не используется |

---

## 📋 РЕКОМЕНДАЦИИ

### СРОЧНО:
1. **Проверить версию Jicofo:**
   ```bash
   docker exec jitsi-jicofo-1 cat /version
   ```

2. **Обновить docker-compose.yml:**
   ```yaml
   jicofo:
     image: jitsi/jicofo:unstable  # Поддерживает стратегию
     environment:
       - BRIDGE_SELECTION_STRATEGY=SplitBridgeSelectionStrategy
   ```

3. **Пересоздать контейнер:**
   ```bash
   docker compose up -d --force-recreate jicofo
   ```

### ДОЛГОСРОЧНО:
1. Обновить весь кластер до последних стабильных версий
2. Настроить мониторинг нагрузки на JVB
3. Добавить автоматическое масштабирование

---

## 🔑 ДОСТУПЫ

| Сервер | IP | Логин | Пароль |
|--------|-----|-------|--------|
| VM 130 | 10.0.1.130 | vardo001 | !P09710023p |
| VM 131 | 10.0.1.131 | vardo001 | !P09710023p |
| VM 132 | 10.0.1.132 | vardo001 | !P09710023p |

---

**ДАТА:** 2026-04-02  
**СТАТУС:** OCTO включен, требуется обновление Jicofo для SplitBridgeSelectionStrategy  
**ПОРТАЛ:** https://vks.ahprostory.ru
