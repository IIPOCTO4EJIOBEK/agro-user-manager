# ОТЧЕТ ПО ДИАГНОСТИКЕ LDAP В BITRIX24
## Дата: 24 февраля 2026

---

## ❌ ПРОБЛЕМА: LDAP НЕ РАБОТАЕТ

**Пользователи не могут авторизоваться через LDAP**

---

## 🔍 РЕЗУЛЬТАТЫ ДИАГНОСТИКИ

### 1. LDAP Сервер не работает

```
10.0.1.200:389 (ldap)  - Connection refused ❌
10.0.1.200:636 (ldaps) - Connection refused ❌
```

**LDAP служба не запущена на 10.0.1.200!**

### 2. LDAP настройки в Bitrix24 пустые

```sql
SELECT NAME, VALUE FROM b_option WHERE NAME LIKE '%ldap%';

NAME                    VALUE
-----------------------------------------
import_ldap_server      [ПУСТО]  ❌
ldap_server             [НЕТ]    ❌
ldap_host               [НЕТ]    ❌
ldap_base_dn            [НЕТ]    ❌
ldap_admin_dn           [НЕТ]    ❌
ldap_user_path          [НЕТ]    ❌
```

### 3. NTLM авторизация отключена

```sql
NAME            VALUE
-------------------------------
use_ntlm        N          ❌
ntlm_default_server  1
```

### 4. LDAP пакеты установлены, но служба не работает

```
# На всех узлах установлено:
openldap-2.6.8-4.el9.0.1.x86_64
php-ldap-8.2.30-1.module_php.8.2.el9.remi.x86_64

# Но служба slapd не найдена:
systemctl status slapd → Unit not found ❌
```

---

## 📋 ПРИЧИНЫ ПРОБЛЕМЫ

1. **LDAP сервер не настроен** - `import_ldap_server` пустое значение
2. **LDAP служба не запущена** - порт 389 не слушается
3. **NTLM авторизация отключена** - `use_ntlm = N`
4. **Active Directory контроллер не найден** - 10.0.1.1, 10.0.1.2 не отвечают на 389 порт

---

## 🔧 РЕШЕНИЕ

### ВАРИАНТ 1: Настроить внешний LDAP/AD сервер

Если у вас есть внешний Active Directory или LDAP сервер:

1. **Узнайте адрес LDAP сервера:**
   - Адрес: например, `ldap.company.local` или `192.168.x.x`
   - Порт: 389 (LDAP) или 636 (LDAPS)
   - Base DN: например, `DC=company,DC=local`
   - Admin DN: например, `CN=Administrator,CN=Users,DC=company,DC=local`

2. **Настройте Bitrix24:**
   - Администрирование → Настройки → Настройки продукта → Настройки модулей → LDAP
   - Добавьте LDAP сервер
   - Включите NTLM если нужно

3. **Или через SQL:**
```sql
UPDATE prostory.b_option SET VALUE='ldap.company.local:389' WHERE NAME='import_ldap_server';
UPDATE prostory.b_option SET VALUE='Y' WHERE NAME='use_ntlm';
```

### ВАРИАНТ 2: Поднять локальный LDAP сервер

Если нужен локальный LDAP на 10.0.1.200:

```bash
# Установка OpenLDAP
dnf install -y openldap-servers openldap-clients

# Настройка и запуск
systemctl enable slapd
systemctl start slapd

# Настройка Base DN
slapadd -l /path/to/ldap_dump.ldif
```

### ВАРИАНТ 3: Отключить LDAP авторизацию

Если LDAP не нужен, отключите его в настройках Bitrix:

1. Администрирование → Настройки → Настройки продукта → Настройки модулей → LDAP
2. Отключить LDAP авторизацию
3. Пользователи будут авторизоваться только через локальную БД Bitrix

---

## 📊 ТЕКУЩАЯ КОНФИГУРАЦИЯ

### Веб-узлы (LDAP клиенты):
| Узел | LDAP пакеты | Статус |
|------|-------------|--------|
| 10.0.1.220 | ✅ Установлены | ❌ Не настроен |
| 10.0.1.221 | ✅ Установлены | ❌ Не настроен |
| 10.0.1.222 | ✅ Установлены | ❌ Не настроен |

### LDAP сервер:
| Сервер | Порт | Статус |
|--------|------|--------|
| 10.0.1.200 | 389 | ❌ Не слушается |
| 10.0.1.200 | 636 | ❌ Не слушается |

### Active Directory:
| Контроллер | Порт | Статус |
|------------|------|--------|
| 10.0.1.1 | 389 | ❌ Не отвечает |
| 10.0.1.2 | 389 | ❌ Не отвечает |
| 192.168.1.1 | 389 | ❌ Не отвечает |

---

## 🛠️ КОМАНДЫ ДЛЯ ПРОВЕРКИ

### Проверка LDAP подключения:
```bash
# С локального сервера
ldapsearch -x -H ldap://ldap.company.local -b "DC=company,DC=local" -D "CN=Admin,..." -W

# Проверка порта
nc -zv ldap.company.local 389
```

### Проверка настроек Bitrix:
```bash
ssh root@10.0.1.200
mysql -e "SELECT * FROM prostory.b_option WHERE MODULE_ID='ldap';"
```

### Включение NTLM:
```bash
ssh root@10.0.1.200
mysql -e "UPDATE prostory.b_option SET VALUE='Y' WHERE NAME='use_ntlm';"
```

---

## 📞 НЕОБХОДИМАЯ ИНФОРМАЦИЯ

Для настройки LDAP авторизации уточните:

1. **Где находится LDAP сервер?**
   - [ ] Внешний Active Directory
   - [ ] Внутренний OpenLDAP
   - [ ] Нужно поднять новый

2. **Адрес LDAP сервера:**
   - Hostname/IP: _______________
   - Порт: 389 / 636
   - SSL: Да / Нет

3. **Настройки домена:**
   - Base DN: _______________
   - Admin DN: _______________
   - Пароль: _______________

4. **NTLM авторизация:**
   - [ ] Требуется
   - [ ] Не требуется

---

**СТАТУС: Требуется настройка LDAP сервера и интеграции с Bitrix24** ❌
