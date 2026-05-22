# УПРАВЛЕНИЕ КОНФИГУРАЦИЕЙ BITRIX24 CLUSTER
## ⚠️ ВАЖНО: Как правильно вносить изменения

---

## ❌ ПРОБЛЕМА ТЕКУЩЕЙ СИСТЕМЫ

### Сценарий потери изменений:
```
1. Вы подключились к 10.0.1.221 по SSH
2. Изменили /etc/php-fpm.d/www.conf
3. Сохранили файл
4. Через 5 минут cron запускает синхронизацию
5. 10.0.1.220 (master) копирует СВОЙ файл на 10.0.1.221
6. ❌ ВАШЕ ИЗМЕНЕНИЕ ПОТЕРЯНО!
```

### Почему это происходит:
```
MASTER (10.0.1.220) → SLAVE (10.0.1.221, 222)
      ↓                      ↑
   Источник           Получатель (только чтение!)
```

---

## ✅ ПРАВИЛЬНЫЕ СПОСОБЫ ВНЕСЕНИЯ ИЗМЕНЕНИЙ

### СПОСОБ 1: Через Git (Рекомендуется)

#### Шаг 1: Клонирование репозитория
```bash
# На Ansible master (10.0.1.200)
cd /root/bitrix24-config
git clone /root/bitrix24-config.git work 2>/dev/null || true
```

#### Шаг 2: Внесение изменений
```bash
# Скопируйте измененный файл в репозиторий
cp /etc/php-fpm.d/www.conf /root/bitrix24-config/php-fpm/

# Добавьте в git
cd /root/bitrix24-config
git add .
git commit -m "Изменение параметров PHP-FPM"
git push origin master
```

#### Шаг 3: Применение изменений
```bash
# Запуск Ansible playbook
ansible-playbook -i /etc/ansible/hosts /root/bitrix24-config/deploy.yml
```

---

### СПОСОБ 2: Через Ansible (Без Git)

#### Шаг 1: Изменение playbook
```bash
# На Ansible master (10.0.1.200)
vi /root/bitrix24_sync.yml
# Внесите изменения в конфигурацию
```

#### Шаг 2: Применение ко всем узлам
```bash
ansible-playbook -i /etc/ansible/hosts /root/bitrix24_sync.yml
```

**Результат:**
- ✅ Все узлы получат одинаковую конфигурацию
- ✅ Изменения применятся одновременно
- ✅ Нет риска потери изменений

---

### СПОСОБ 3: Ручная синхронизация (Одноразовые изменения)

#### Если вы изменили файл на одном из узлов:

```bash
# 1. Скопируйте измененный файл на master
scp /etc/php-fpm.d/www.conf root@10.0.1.220:/tmp/www.conf.new

# 2. На master замените файл
ssh root@10.0.1.220 "cp /tmp/www.conf.new /etc/php-fpm.d/www.conf"

# 3. Запустите синхронизацию вручную
ssh root@10.0.1.220 "/root/bitrix24_rsync_sync.sh"
```

---

## 📋 АРХИТЕКТУРА ПРАВИЛЬНОЙ СИНХРОНИЗАЦИИ

```
┌─────────────────────────────────────────────────────┐
│           ЕДИНЫЙ ИСТОЧНИК ИСТИНЫ                    │
│  Ansible Master (10.0.1.200) + Git Repository      │
└─────────────────────────────────────────────────────┘
                          │
              ┌───────────┼───────────┐
              ↓           ↓           ↓
        ┌─────────┐ ┌─────────┐ ┌─────────┐
        │  10.0.  │ │  10.0.  │ │  10.0.  │
        │  1.220  │ │  1.221  │ │  1.222  │
        │ (MASTER)│ │ (SLAVE) │ │ (SLAVE) │
        └─────────┘ └─────────┘ └─────────┘
              │           │           │
              └───────────┴───────────┘
                          │
              Автоматическая синхронизация
              (только от master к slave)
```

---

## 🔒 ЗАПРЕТ ПРЯМЫХ ИЗМЕНЕНИЙ НА SLAVE

### Опционально: Сделать файлы только для чтения на slave

```bash
# На 10.0.1.221 и 10.0.1.222
chattr +i /etc/php-fpm.d/www.conf
chattr +i /etc/httpd/conf.d/php.conf
chattr +i /home/bitrix/www/bitrix/license_key.php
```

**Результат:**
- Файлы нельзя изменить даже root
- Попытка записи: `Operation not permitted`
- Снимается через `chattr -i`

---

## 📊 СРАВНЕНИЕ ПОДХОДОВ

| Подход | Безопасность | Удобство | Откат | Рекомендация |
|--------|--------------|----------|-------|--------------|
| Git + Ansible | ✅ Высокая | ⚠️ Средняя | ✅ Есть | ✅ Рекомендуется |
| Ansible только | ✅ Высокая | ⚠️ Средняя | ⚠️ Частичный | ✅ Хорошо |
| Ручная синхронизация | ⚠️ Средняя | ✅ Высокое | ❌ Нет | ⚠️ Только для срочных изменений |
| Прямые изменения на узлах | ❌ Опасно | ✅ Высокое | ❌ Нет | ❌ ЗАПРЕЩЕНО |

---

## 🚀 НАСТРОЙКА GIT + ANSIBLE (ПОШАГОВО)

### Шаг 1: Создание репозитория
```bash
# На 10.0.1.200 (Ansible master)
mkdir -p /root/bitrix24-config
cd /root/bitrix24-config
git init

# Копирование текущей конфигурации
cp /etc/ansible/hosts ./
cp /root/bitrix24_sync.yml ./deploy.yml
mkdir -p php-fpm apache bitrix
cp /etc/php-fpm.d/www.conf php-fpm/
cp /etc/httpd/conf.d/php.conf apache/
cp /home/bitrix/www/bitrix/license_key.php bitrix/

git add .
git commit -m "Initial commit - текущая конфигурация кластера"
```

### Шаг 2: Изменение конфигурации
```bash
# Внесение изменений
vi /root/bitrix24-config/php-fpm/www.conf

# Фиксация изменений
cd /root/bitrix24-config
git add .
git commit -m "Увеличено pm.max_children до 150"

# Применение изменений
ansible-playbook -i ./hosts ./deploy.yml
```

---

## 📋 ЧЕК-ЛИСТ: Как вносить изменения

### ✅ ПРАВИЛЬНО:
1. [ ] Изменения вносятся на Ansible master (10.0.1.200)
2. [ ] Фиксируются в Git
3. [ ] Применяются через Ansible playbook
4. [ ] Проверяется статус всех узлов

### ❌ НЕПРАВИЛЬНО:
1. [ ] Прямое изменение файлов на 10.0.1.221/222
2. [ ] Сохранение конфигов без фиксации в Git
3. [ ] Применение изменений только на одном узле

---

## 🔧 УТИЛИТЫ ДЛЯ УПРАВЛЕНИЯ

### bitrix24-config-save
```bash
#!/bin/bash
# Сохранение текущей конфигурации с master в Git
cd /root/bitrix24-config
cp /etc/php-fpm.d/www.conf php-fpm/
cp /etc/httpd/conf.d/php.conf apache/
git add .
git commit -m "Auto-save: $(date)"
git push origin master
```

### bitrix24-config-deploy
```bash
#!/bin/bash
# Применение конфигурации из Git
cd /root/bitrix24-config
git pull origin master
ansible-playbook -i ./hosts ./deploy.yml
```

---

## 📞 ЭКСТРЕННАЯ ПОМОЩЬ

### Если изменения потеряны:
```bash
# 1. Проверка Git истории
cd /root/bitrix24-config
git log --oneline -10

# 2. Откат к предыдущей версии
git checkout <commit-hash> -- php-fpm/www.conf

# 3. Применение изменений
ansible-playbook -i ./hosts ./deploy.yml
```

### Если синхронизация сломалась:
```bash
# Ручная синхронизация
/root/bitrix24_rsync_sync.sh

# Проверка MD5
for ip in 10.0.1.220 10.0.1.221 10.0.1.222; do
    echo "=== $ip ==="
    ssh root@$ip 'md5sum /etc/php-fpm.d/www.conf'
done
```

---

## 📚 ДОПОЛНИТЕЛЬНАЯ ДОКУМЕНТАЦИЯ

- `/root/СИСТЕМА_СИНХРОНИЗАЦИИ_CLUSTER.md` - Настройка rsync
- `/root/ОТЧЕТ_PHP-FPM_НАСТРОЙКА.md` - Конфигурация PHP-FPM
- `/root/bitrix24_sync.yml` - Ansible playbook

---

**⚠️ ЗАПОМНИТЕ: Никогда не изменяйте файлы напрямую на slave-узлах (10.0.1.221, 10.0.1.222)!**
