# ОТЧЕТ: LDAP ИМПОРТ НЕ РАБОТАЕТ
## Дата: 24 февраля 2026

---

## ✅ ЧТО ПРОВЕРЕНО И РАБОТАЕТ

### 1. LDAP Сервер доступен
```
✅ 10.1.20.21:389 - подключено
✅ LDAP Bind OK (rusagroeco\bitrix_ad)
✅ Поиск пользователей работает (найдено 10)
✅ Поиск OU работает (найдено 10)
```

### 2. Настройки в БД правильные
```sql
ID: 1
NAME: pdc-dc1
SERVER: ldap://10.1.20.21:389
BASE_DN: DC=rusagroeco,DC=ru
ADMIN_LOGIN: rusagroeco\bitrix_ad
ACTIVE: Y
SYNC: Y
SYNC_PERIOD: 1 (каждый час)
```

### 3. LDAP модуль загружен
```
✓ Модуль ldap загружен
✓ Сервер найден в БД
✓ Файлы модуля на месте
✓ Права правильные (bitrix:bitrix)
```

### 4. HAProxy/Nginx не блокируют
```
✅ Доступ к /bitrix/admin/ldap_*.php → HTTP 200
✅ Админ-трафик идет на MASTER (10.0.1.220)
```

### 5. Таймауты PHP увеличены
```
max_execution_time = 600 (было 300)
max_input_time = 600
```

---

## ❌ ПРОБЛЕМА

**LDAP пользователей в БД: 0**

Синхронизация не импортировала пользователей, хотя:
- Сервер настроен
- Подключение работает
- Модуль загружен
- Права правильные

---

## 🔧 ВОЗМОЖНЫЕ ПРИЧИНЫ

### 1. Фильтр пользователей слишком строгий
```ldap
(&(objectClass=user)(objectCategory=person)
 (!(userAccountControl:1.2.840.113556.1.4.803:=2))
 (!(isCriticalSystemObject=TRUE))
 (|
  (OU=RND,DC=rusagroeco,DC=ru)
  (OU=STV,DC=rusagroeco,DC=ru)
  (OU=KRD,DC=rusagroeco,DC=ru)
  (OU=NIZ,DC=rusagroeco,DC=ru)
  (OU=MSK,DC=rusagroeco,DC=ru)
  (OU=Special,DC=rusagroeco,DC=ru)
 )
)
```

**Проблема:** Пользователи могут быть в других OU

### 2. Недостаточно прав у bitrix_ad
**Проблема:** Нет прав на чтение OU с пользователями

### 3. Ошибка при импорте (не логируется)
**Проблема:** Bitrix не пишет ошибки импорта в лог

### 4. Группы не настроены
**Проблема:** Группа "Пользователи домена" → "Агрохолдинг ПРОСТОРЫ: Сотрудники [12]" не мапится

---

## 🛠️ РЕШЕНИЕ

### Шаг 1: Упростить фильтр для теста

**В админ-панели:**
1. LDAP → Серверы → pdc-dc1 → Редактировать
2. Вкладка "Настройки сервера"
3. **Фильтр для пользователей:**
   ```
   (&(objectClass=user)(objectCategory=person))
   ```
4. Сохранить

### Шаг 2: Запустить синхронизацию

**В админ-панели:**
1. LDAP → Серверы → pdc-dc1
2. Кнопка **"Синхронизировать"**
3. Ждать 1-5 минут

### Шаг 3: Проверить результат

**SQL проверка:**
```sql
SELECT COUNT(*) FROM b_user WHERE EXTERNAL_AUTH_ID='ldap';
-- Должно быть > 0
```

**В админ-панели:**
1. LDAP → Пользователи
2. Должны появиться пользователи

### Шаг 4: Если не помогло - проверить права bitrix_ad

**На контроллере домена (PowerShell):**
```powershell
# Проверка прав
dsacls "OU=RND,DC=rusagroeco,DC=ru" | findstr bitrix_ad

# Дать права на чтение (если нужно)
dsacls "OU=RND,DC=rusagroeco,DC=ru" /G "rusagroeco\bitrix_ad:CC;user;readprop"
```

### Шаг 5: Включить логирование LDAP

**В .settings.php:**
```php
'ldap' => [
  'value' => [
    'debug' => true,
  ],
],
```

**Лог:**
```
/home/bitrix/www/bitrix/modules/ldap/log/
```

---

## 📊 ЧТО Я МЕНЯЛ

### Файлы которые трогал:
1. `/etc/php.d/bitrixenv.ini` - таймауты (300→600)
2. `/home/bitrix/www/bitrix/tmp/` - права (удалил test_*)
3. `/home/bitrix/www/bitrix/` - права (775 bitrix:bitrix)
4. `/home/bitrix/www/auth/.htaccess` - создал

### Что НЕ менял:
- ❌ Настройки LDAP в БД
- ❌ Файлы модуля ldap
- ❌ Конфигурацию HAProxy для LDAP
- ❌ Пути к файлам Bitrix

### HAProxy:
- Админ-панель → MASTER (10.0.1.220) ✓
- Обычный трафик → балансировка ✓

---

## ✅ ПРОВЕРКИ

### 1. Тест подключения:
```bash
ssh root@10.0.1.220
php -r '
$ldap = ldap_connect("ldap://10.1.20.21:389");
ldap_bind($ldap, "rusagroeco\\bitrix_ad", "Confirmation1709");
echo ldap_error($ldap);
'
# Должно быть: OK
```

### 2. Проверка пользователей в БД:
```sql
SELECT COUNT(*) FROM b_user WHERE EXTERNAL_AUTH_ID='ldap';
# Должно быть > 0 после импорта
```

### 3. Проверка логов:
```bash
tail -100 /var/log/httpd/error_log | grep -i ldap
```

---

## 📋 ПЛАН ДЕЙСТВИЙ

1. **Упростить фильтр** (убрать OU restriction)
2. **Запустить синхронизацию** через админку
3. **Проверить** через SQL
4. **Если 0** - проверить права bitrix_ad в AD
5. **Если ошибка** - включить debug логирование

---

**СТАТУС:** Требуется ручное вмешательство для настройки фильтра и запуска импорта
