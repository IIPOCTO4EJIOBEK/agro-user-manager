# Сводный отчет по учетным данным проекта Битрикс24 "ПРОСТОРЫ"

## 1. Системные серверы (Linux/Windows)

| Роль | IP | Пользователь | Пароль |
|------|----|--------------|--------|
| **Nginx Proxy** | 10.0.1.110 | vardo001 / root | `!P09710023p` |
| **HAProxy** | 10.0.1.50 | vardo001 / root | `!P09710023p` |
| **Web 01 (Master)** | 10.0.1.220 | vardo001 / root | `!P09710023p` |
| **Web 02** | 10.0.1.221 | vardo001 / root | `!P09710023p` |
| **Web 03** | 10.0.1.222 | vardo001 / root | `!P09710023p` |
| **Database** | 10.0.1.200 | vardo001 / root | `!P09710023p` |
| **Redis** | 10.0.1.210 | vardo001 / root | `!P09710023p` |
| **Push Server** | 10.0.1.230 | vardo001 / root | `!P09710023p` |
| **AD Sync (Win)** | 10.0.1.250 | Administrator@sync.rusagroeco.ru | `Admin@2026Prostory!` |

## 2. Инфраструктурные сервисы

*   **MySQL (Primary):**
    *   Пользователь: `bitrix`
    *   Пароль: `S0m3_Str0ng_Pass!`
    *   БД: `prostory`
*   **Redis (Cache/Session):**
    *   Пароль: `B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!`
*   **Push & Pull (Node.js):**
    *   Signature Key: `azTw0fWfYZeOU4JrzXu3UTXtcrWZePoRuAnYCNn9oKRwQIfLqmOYvqRVfJ9s1lZyj5B1L9AWDlFKgpQgX7xEa1MzEUkrkg8suA4qcQVl7UnvJwHoibkhSyvHho6kOGuE`

## 3. Active Directory (LDAP)

*   **PDc-DC1 (Основной домен):**
    *   Сервер: `ldap://10.1.20.21:389`
    *   Base DN: `DC=rusagroeco,DC=ru`
    *   Пользователь: `rusagroeco\bitrix_ad`
    *   Пароль: `Confirmation1709`
*   **AD 250 Ideal (Промежуточный/Синхрон):**
    *   Сервер: `ldap://10.0.1.250:389`
    *   Base DN: `OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru`
    *   Пользователь: `Administrator@sync.rusagroeco.ru`
    *   Пароль: `Admin@2026Prostory!`

## 4. Портал Битрикс24

*   **URL:** `https://b24.ahprostory.ru/`
*   **Логин (Admin):** `agroadmin`
*   **Пароль (Admin):** `@groAdm54_2026`
*   **Лицензионный ключ:** `P25-ML-PLBNQN7UM28BGK5XQMSI` (Энтерпрайз 1000)
