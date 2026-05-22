# 📊 JITSI CLUSTER MONITORING SYSTEM v3.4
## Полная документация системы мониторинга Jitsi Cluster

**Дата обновления:** 26 Февраля 2026  
**Версия:** v3.4  
**Статус:** ✅ Работает

---

## 🌐 ДОСТУПЫ И URL

| Сервис | URL | Порт | Статус |
|--------|-----|------|--------|
| **Веб-интерфейс (HTTP)** | http://10.0.1.110:8088/ | 8088 | ✅ |
| **Веб-интерфейс (HTTPS)** | https://stat.vks.ahprostory.ru/ | 443 | ✅ |
| **Jitsi Meet** | https://vks.ahprostory.ru/ | 443 | ✅ |

### Учетные данные:
```
SSH пользователь: vardo001
SSH пароль: !P09710023p
```

---

## 🏗️ АРХИТЕКТУРА СИСТЕМЫ

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    INTERNET (185.160.36.97)                              │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              10.0.1.110 (Proxy & Statistics Server)                      │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Nginx Proxy Manager (Docker)                                    │   │
│  │  - Порт 80, 443, 8088                                            │   │
│  │  - SSL: Let's Encrypt (npm-26)                                   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  jitsi-stats-backend (Docker)                                    │   │
│  │  - Flask Python App                                              │   │
│  │  - Порт: 80 (внутри), 8088 (наружу)                              │   │
│  │  - Файл: /root/npm/app.py                                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│  10.0.1.130     │   │  10.0.1.131     │   │  10.0.1.132     │
│  Control Plane  │   │  Media Node 1   │   │  Media Node 2   │
├─────────────────┤   ├─────────────────┤   ├─────────────────┤
│ Prosody (XMPP)  │   │ JVB (Video)     │   │ JVB (Video)     │
│ Jicofo          │   │ API: 8080       │   │ API: 8080       │
│ Web             │   │                 │   │                 │
│ Grafana         │   │                 │   │                 │
│ Prometheus      │   │                 │   │                 │
└─────────────────┘   └─────────────────┘   └─────────────────┘
         │
         ▼
┌─────────────────┐
│  10.0.1.133     │
│  Recorder       │
├─────────────────┤
│ Записи:         │
│ /recordings/    │
│ *.mp4           │
└─────────────────┘
```

---

## 📁 СТРУКТУРА ФАЙЛОВ

### На сервере 10.0.1.110:

```
/root/npm/
├── app.py                    # Главный скрипт мониторинга (v3.4)
├── docker-compose.yml        # Конфигурация Docker
└── data/
    ├── database.sqlite       # База данных NPM
    ├── logs/
    │   ├── proxy-host-1_access.log  # Логи доступа vks.ahprostory.ru
    │   ├── proxy-host-2_access.log  # Логи доступа stat.vks.ahprostory.ru
    │   └── ...
    ├── nginx/
    │   ├── proxy_host/
    │   │   └── 2.conf        # Конфиг прокси для статистики
    │   └── conf.d/
    │       └── include/
    │           └── proxy.conf # Прокси конфигурация
    └── custom/
        ├── http_top.conf     # worker_rlimit_nofile 65535
        └── events.conf       # worker_connections 65535
```

---

## 💻 ПОЛНЫЙ КОД app.py

```python
from flask import Flask, render_template_string, request, redirect
import os, subprocess, re, datetime, requests, json

app = Flask(__name__)

PASS = '!P09710023p'
DOMAIN = 'vks.ahprostory.ru'
JVB_NODES = ['10.0.1.131', '10.0.1.132']
NODES = [
    {'ip': '10.0.1.130', 'name': 'Control Plane (130)'},
    {'ip': '10.0.1.131', 'name': 'Media Node 1 (131)'},
    {'ip': '10.0.1.132', 'name': 'Media Node 2 (132)'},
    {'ip': '10.0.1.133', 'name': 'Recorder (133)'}
]

geo_cache = {}

def get_msk_time():
    return (datetime.datetime.utcnow() + datetime.timedelta(hours=3)).strftime('%H:%M:%S')

def get_geo(ip):
    if not ip or ip in ['N/A', '-', 'Internal'] or ip.startswith(('10.', '172.', '192.')): 
        return 'Internal'
    if ip in geo_cache: 
        return geo_cache[ip]
    try:
        r = requests.get(f'http://ip-api.com/json/{ip}?fields=countryCode,city', timeout=0.5).json()
        loc = f"{r.get('countryCode', '??')} {r.get('city', '??')}"
        geo_cache[ip] = loc
        return loc
    except: 
        return 'N/A'

def get_node_status(ip):
    try:
        cmd = f"sshpass -p '{PASS}' ssh -o StrictHostKeyChecking=no vardo001@{ip} 'uptime && free -m'"
        out = subprocess.check_output(cmd, shell=True, timeout=2).decode()
        load = out.split('load average:')[1].split(',')[0].strip()
        mem = re.search(r'Mem:\s+(\d+)\s+(\d+)', out)
        mem_str = f"{mem.group(2)}MB free" if mem else "-"
        return {'load': load, 'mem': mem_str, 'status': 'Online'}
    except: 
        return {'load': '-', 'mem': '-', 'status': 'Offline'}

def get_recordings():
    try:
        cmd = f"sshpass -p '{PASS}' ssh -o StrictHostKeyChecking=no vardo001@10.0.1.133 'find /recordings -name \"*.mp4*\" -exec ls -lh --time-style=long-iso {{}} \\;'"
        out = subprocess.check_output(cmd, shell=True, timeout=10).decode()
        files = []
        for line in out.split('\n'):
            if not line: continue
            parts = line.split()
            if len(parts) >= 8:
                full_path = parts[-1]
                filename = os.path.basename(full_path)
                room_match = re.match(r'^(.+?)_\d{{4}}-\d{{2}}-\d{{2}}', filename)
                room_display = room_match.group(1) if room_match else filename.replace('.mp4', '')
                files.append({
                    'name': room_display,
                    'rel_path': full_path.replace('/recordings/', ''),
                    'size': parts[4],
                    'date': f"{parts[5]} {parts[6]}"
                })
        return sorted(files, key=lambda x: x['date'], reverse=True)[:30]
    except Exception as e:
        print(f"Error getting recordings: {e}")
        return []

def get_room_ips():
    """Парсим логи NPM и возвращаем маппинг room -> последний IP"""
    room_ips = {}
    try:
        log_path = "/app/data/logs/proxy-host-1_access.log"
        if os.path.exists(log_path):
            with open(log_path, 'r') as f:
                # Берем последние 500 строк
                lines = f.readlines()[-500:]
                for line in lines:
                    # Ищем строки вида: /xmpp-websocket?room=ROOMNAME
                    match = re.search(r'room=([a-zA-Z0-9_-]+).*?\[Client (\d+\.\d+\.\d+\.\d+)\]', line)
                    if match:
                        room_name = match.group(1)
                        client_ip = match.group(2)
                        # Пропускаем внутренние IP
                        if not client_ip.startswith(('10.', '172.', '192.')):
                            room_ips[room_name] = client_ip
    except Exception as e:
        print(f"Error parsing room IPs: {e}")
    return room_ips

def get_active_data():
    rooms = {}
    
    # 1. Получаем маппинг комнат -> IP из логов NPM
    room_ips = get_room_ips()
    
    # 2. Опрос JVB
    for jvb_ip in JVB_NODES:
        try:
            cmd = f"sshpass -p '{PASS}' ssh -o StrictHostKeyChecking=no vardo001@{jvb_ip} 'curl -s http://localhost:8080/debug'"
            data = json.loads(subprocess.check_output(cmd, shell=True, timeout=2).decode())
            if 'conferences' in data:
                for cid, conf in data['conferences'].items():
                    rname = conf.get('name', 'Unknown').split('@')[0]
                    if rname not in rooms: 
                        rooms[rname] = {'members': {}, 'jvb': jvb_ip}
                    if 'endpoints' in conf:
                        for eid, dname in conf['endpoints'].items():
                            if 'jibri' in eid: continue
                            # Имя напрямую из JVB API (display_name)
                            name = dname or eid
                            # Берем IP для конкретной комнаты
                            ip = room_ips.get(rname, 'N/A')
                            rooms[rname]['members'][eid] = {'name': name, 'ip': ip, 'loc': get_geo(ip)}
        except: continue
    return rooms

@app.route('/')
def index():
    now = get_msk_time()
    rooms = get_active_data()
    recs = get_recordings()
    node_stats = {n['ip']: get_node_status(n['ip']) for n in NODES if n['ip'] in JVB_NODES}
    
    html = """
    <html><head><meta charset='utf-8'><title>Jitsi Cluster v3.4</title>
    <style>
        body{background:#0b1120; color:#f1f5f9; font-family:sans-serif; padding:40px; margin:0;}
        .card{background:#1e293b; border:1px solid #334155; border-radius:12px; padding:20px; margin-bottom:20px;}
        h1{color:#38bdf8; margin:0;} h3{color:#94a3b8; font-size:0.9em; text-transform:uppercase; margin-top:30px;}
        .btn{padding:10px 20px; border-radius:8px; cursor:pointer; text-decoration:none; display:inline-block; font-weight:600; background:#0ea5e9; color:white; border:none;}
        .btn-red{background:#ef4444;}
        table{width:100%; border-collapse:collapse;} th{text-align:left; color:#94a3b8; font-size:12px; padding:10px; border-bottom:1px solid #334155; text-transform:uppercase;}
        td{padding:12px 10px; border-bottom:1px solid #334155;}
        .ip{font-family:monospace; color:#7dd3fc; background:#0f172a; padding:2px 6px; border-radius:4px;}
        input[type=checkbox]{transform:scale(1.3); margin:10px;}
    </style></head><body>
        <div style='display:flex; justify-content:space-between; align-items:center; margin-bottom:30px;'>
            <div><h1>Jitsi Cluster Master v3.4</h1>
                <div style='margin-top:10px;'>
                {% for ip, s in stats.items() %}
                    <span style='margin-right:15px; font-size:13px;'>● Node {{ip.split('.')[-1]}}: <b>{{s.load}}</b> | {{s.mem}}</span>
                {% endfor %}
                </div>
            </div>
            <div style='text-align:right'><b>{{ now }} MSK</b><br><br><a href='/' class='btn'>Force Refresh</a></div>
        </div>
        <div class='card'>
            <h3>Active Conferences</h3>
            <table>
                <tr><th>Room / Bridge</th><th>Participants</th><th style='text-align:right'>Action</th></tr>
                {% for r, d in rooms.items() %}
                <tr>
                    <td><b>{{ r }}</b><br><small style='color:#64748b'>{{ d.jvb }}</small></td>
                    <td>
                        {% for eid, u in d.members.items() %}
                        <div style='margin-bottom:5px;'><b style='color:#e2e8f0'>{{ u.name }}</b> <span class='ip'>{{ u.ip }}</span> <small style='color:#94a3b8'>{{ u.loc }}</small></div>
                        {% endfor %}
                    </td>
                    <td style='text-align:right'><a href='/delete/room/{{r}}' class='btn btn-red' onclick="return confirm('Stop {{r}}?')">STOP</a></td>
                </tr>
                {% endfor %}
                {% if not rooms %}<tr><td colspan='3' style='text-align:center; padding:40px;'>No active video streams.</td></tr>{% endif %}
            </table>
        </div>
        <h3>Recent Recordings</h3>
        <div class='card' style='padding:0;'>
        {% if recs %}
        <form action='/delete/files' method='POST' onsubmit="return confirm('Delete selected recordings?')">
            <table>
                <tr style='background:#1e293b;'><th style='padding-left:20px; width:40px;'><input type='checkbox' id='selectAll' onclick="var c=document.getElementsByName('files'); for(var i=0;i<c.length;i++) c[i].checked=this.checked;"></th><th>Name</th><th>Size</th><th>Date</th></tr>
                {% for r in recs %}
                <tr><td style='padding-left:20px;'><input type='checkbox' name='files' value='{{r.rel_path}}'></td><td><b style='color:#38bdf8'>{{r.name}}</b></td><td>{{r.size}}</td><td>{{r.date}}</td></tr>
                {% endfor %}
            </table>
            <button type='submit' class='btn btn-red' style='margin:15px;'>Delete Selected</button>
        </form>
        {% else %}
        <p style='padding:20px; color:#64748b;'>No recordings found.</p>
        {% endif %}
        </div>
    </body></html>
    """
    return render_template_string(html, rooms=rooms, now=now, recs=recs, stats=node_stats)

@app.route('/delete/room/<room>')
def delete_room(room):
    os.system(f"sshpass -p '{PASS}' ssh -o StrictHostKeyChecking=no vardo001@10.0.1.130 'echo {PASS} | sudo -S docker exec jitsi-prosody-1 prosodyctl mod_muc_admin_room_destroy {room}@conference.vks.ahprostory.ru'")
    return redirect('/')

@app.route('/delete/files', methods=['POST'])
def delete_files():
    for f in request.form.getlist('files'):
        if f and '..' not in f:
            os.system(f"sshpass -p '{PASS}' ssh -o StrictHostKeyChecking=no vardo001@10.0.1.133 'echo {PASS} | sudo -S rm -rf /recordings/{f}'")
    return redirect('/')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
```

---

## 🔄 ПОТОК ДАННЫХ (DATA FLOW)

```
1. Пользователь открывает https://stat.vks.ahprostory.ru/
   │
   ▼
2. Nginx Proxy Manager (10.0.1.110:443)
   │ SSL терминация
   │ Прокси на 172.18.0.3:80
   ▼
3. jitsi-stats-backend контейнер
   │ Запуск app.py
   │ Flask обрабатывает GET /
   ▼
4. Сбор данных (параллельно):
   │
   ├──▶ get_node_status() → SSH на 130, 131, 132, 133
   │                        uptime && free -m
   │
   ├──▶ get_room_ips() → Чтение proxy-host-1_access.log
   │                      Regex: room=ROOM.*?[Client IP]
   │                      Результат: {'it': '188.168.8.31', 'testroom': '83.221.219.226'}
   │
   ├──▶ get_active_data() → SSH на 131, 132
   │                         curl http://localhost:8080/debug
   │                         JSON: conferences → endpoints
   │
   └──▶ get_recordings() → SSH на 133
                           find /recordings -name "*.mp4*"
   │
   ▼
5. Объединение данных:
   Для каждой комнаты:
   - Имя участника: из JVB API (display_name)
   - IP: из логов NPM (последний для комнаты)
   - Geo: ip-api.com API (кэшируется)
   │
   ▼
6. Рендеринг HTML шаблона
   │
   ▼
7. Возврат пользователю
```

---

## 📊 ИСТОЧНИКИ ДАННЫХ

### 1. Статус узлов (CPU/RAM)
```bash
ssh vardo001@10.0.1.130 'uptime && free -m'
ssh vardo001@10.0.1.131 'uptime && free -m'
ssh vardo001@10.0.1.132 'uptime && free -m'
```

**Парсинг:**
- Load: `load average: 0.08, 0.15, 0.10` → `0.08`
- RAM: `Mem: 32000 29000 3000` → `29000MB free`

### 2. Активные конференции (JVB API)
```bash
ssh vardo001@10.0.1.131 'curl -s http://localhost:8080/debug'
```

**Ответ JSON:**
```json
{
  "conferences": {
    "96ba39065a1765f3": {
      "name": "it@muc.vks.ahprostory.ru",
      "endpoints": {
        "5e4d5876": "Laurine-KZK",
        "ee4ce932": "Dorthy-pj5",
        "91b67f56": "Lucinda-Nyk"
      }
    }
  }
}
```

### 3. IP-адреса (NPM логи)
**Файл:** `/root/npm/data/logs/proxy-host-1_access.log`

**Формат строки:**
```
[26/Feb/2026:14:40:18 +0000] - 200 200 - GET https vks.ahprostory.ru "/xmpp-websocket?room=it&previd=gx9h0u_PMLJo" [Client 176.114.82.153] [Length 379] ...
```

**Regex:**
```python
r'room=([a-zA-Z0-9_-]+).*?\[Client (\d+\.\d+\.\d+\.\d+)\]'
```

**Результат:**
```python
{'it': '176.114.82.153', 'testroom': '83.221.219.226'}
```

### 4. Geo-локация (ip-api.com)
```python
requests.get(f'http://ip-api.com/json/{ip}?fields=countryCode,city', timeout=0.5)
```

**Ответ:**
```json
{"countryCode":"RU","city":"Moscow"}
```

**Результат:** `RU Moscow`

### 5. Записи (Jibri)
```bash
ssh vardo001@10.0.1.133 'find /recordings -name "*.mp4*" -exec ls -lh --time-style=long-iso {} \;'
```

**Вывод:**
```
-rw-r--r-- 1 lxd 997 42M Feb 25 14:55 /recordings/2105979f-a47a-4906-a6bc-a70eda5fd64a/byhnn_2026-02-25-14-39-03.mp4
```

---

## 🔧 КОНФИГУРАЦИЯ NGINX PROXY MANAGER

### /data/nginx/proxy_host/2.conf
```nginx
server {
  set $forward_scheme http;
  set $server         "172.18.0.3";  # Docker IP бекенда
  set $port           80;             # Порт Flask внутри контейнера

  listen 80;
  listen 443 ssl;

  server_name stat.vks.ahprostory.ru;

  # SSL
  ssl_certificate /etc/letsencrypt/live/npm-26/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/npm-26/privkey.pem;

  location / {
    proxy_pass $forward_scheme://$server:$port;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_http_version 1.1;
    proxy_buffering off;
    proxy_cache off;
  }
}
```

### /data/nginx/conf.d/include/proxy.conf
```nginx
# Basic Proxy Config
set $upstream_server $forward_scheme://$server:$port;

proxy_pass $upstream_server;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Real-IP $remote_addr;

# WebSocket support
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $http_connection;

# Timeouts
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;

# Buffering
proxy_buffering off;
proxy_cache off;
```

### /data/nginx/custom/http_top.conf
```nginx
worker_rlimit_nofile 65535;
```

### /data/nginx/custom/events.conf
```nginx
worker_connections 65535;
```

---

## 🐳 DOCKER COMPOSE

### /root/npm/docker-compose.yml
```yaml
version: '3.8'
services:
  npm:
    image: jc21/nginx-proxy-manager:latest
    container_name: npm
    restart: always
    ports:
      - '80:80'
      - '443:443'
      - '10000:10000/udp'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt

  stats:
    image: python:3.9-slim
    container_name: jitsi-stats-backend
    restart: always
    ports:
      - '8088:80'
    volumes:
      - .:/app
    working_dir: /app
    command: bash -c 'apt-get update && apt-get install -y sshpass curl && pip install flask requests && python app.py'
```

---

## 🔐 БЕЗОПАСНОСТЬ

### Хранение паролей
⚠️ **Пароль захардкожен в app.py:**
```python
PASS = '!P09710023p'
```

**Рекомендация:** Вынести в ENV:
```python
PASS = os.environ.get('SSH_PASS', '!P09710023p')
```

### SSH доступ
```bash
sshpass -p '!P09710023p' ssh -o StrictHostKeyChecking=no vardo001@10.0.1.130
```

⚠️ **StrictHostKeyChecking=no** — отключена проверка ключей (риск MITM)

### GeoIP API
```python
http://ip-api.com/json/{ip}
```
⚠️ **HTTP (не HTTPS)** — данные передаются открыто

---

## ⚠️ ИЗВЕСТНЫЕ ОГРАНИЧЕНИЯ

### 1. IP-адреса "скачут"
**Проблема:** Все участники одной комнаты получают одинаковый IP (последний из лога)

**Причина:** JVB API не отдаёт IP участников, только display_name

**Логика:**
```
Комната "it" имеет 5 участников:
- Laurine-KZK → 176.114.82.153 (последний IP из лога для "it")
- Dorthy-pj5 → 176.114.82.153
- Lucinda-Nyk → 176.114.82.153
```

**Фактические IP могут отличаться!**

### 2. Задержка данных
- Данные актуальны на момент обновления страницы
- Нет WebSocket для real-time обновлений
- Force Refresh требует полной перезагрузки

### 3. Зависимость от логов NPM
- Если логи ротируются/очищаются — IP пропадают
- Требуется минимум 1 WebSocket подключение для появления IP

---

## 🛠️ УПРАВЛЕНИЕ

### Перезапуск статистики
```bash
sshpass -p '!P09710023p' ssh vardo001@10.0.1.110 \
  'echo "!P09710023p" | sudo -S docker restart jitsi-stats-backend'
```

### Просмотр логов
```bash
sshpass -p '!P09710023p' ssh vardo001@10.0.1.110 \
  'echo "!P09710023p" | sudo -S docker logs --tail 50 jitsi-stats-backend'
```

### Обновление кода
```bash
# 1. Скопировать новый app.py на сервер
scp app.py vardo001@10.0.1.110:/tmp/app.py

# 2. Заменить и перезапустить
ssh vardo001@10.0.1.110 \
  'echo "!P09710023p" | sudo -S cp /tmp/app.py /root/npm/app.py && 
   sudo -S docker restart jitsi-stats-backend'
```

### Удаление комнаты (через API)
```bash
curl https://stat.vks.ahprostory.ru/delete/testroom
```

---

## 📈 МЕТРИКИ ПРОИЗВОДИТЕЛЬНОСТИ

| Операция | Время | Примечание |
|----------|-------|------------|
| Загрузка страницы | < 1 сек | При наличии данных |
| SSH к узлам | 200-500ms | На каждый узел |
| JVB API запрос | < 100ms | На каждый JVB |
| GeoIP API | < 500ms | Кэшируется |
| Чтение логов | < 100ms | Последние 500 строк |

---

## 📋 КОНТРОЛЬНЫЙ СПИСОК ПРОВЕРКИ

### Ежедневно:
- [ ] Статус: https://stat.vks.ahprostory.ru/ доступен
- [ ] Node 131, 132: Online (зелёные)
- [ ] Активные комнаты отображаются
- [ ] IP-адреса не N/A

### Еженедельно:
- [ ] Логи NPM не переполнены
- [ ] Место на диске 10.0.1.110: < 80%
- [ ] Записи на 10.0.1.133: архивировать старые

### Ежемесячно:
- [ ] SSL сертификат npm-26: действителен
- [ ] Обновить Flask/Python зависимости
- [ ] Резервное копирование app.py

---

## 🆘 УСТРАНЕНИЕ НЕИСПРАВНОСТЕЙ

### 502 Bad Gateway
**Причина:** Бекенд не доступен

**Решение:**
```bash
ssh vardo001@10.0.1.110
echo "!P09710023p" | sudo -S docker ps | grep stats
echo "!P09710023p" | sudo -S docker restart jitsi-stats-backend
```

### 504 Gateway Timeout
**Причина:** Nginx не может подключиться к бекенду

**Решение:**
```bash
# Проверить конфиг
ssh vardo001@10.0.1.110
echo "!P09710023p" | sudo -S docker exec npm cat /data/nginx/proxy_host/2.conf | grep server
# Должно быть: set $server 172.18.0.3; set $port 80;
```

### N/A вместо IP
**Причина:** Нет записей в логах NPM для этой комнаты

**Решение:**
1. Подождать WebSocket подключения
2. Проверить логи: `tail -100 /root/npm/data/logs/proxy-host-1_access.log`
3. Обновить страницу

### Все IP одинаковые
**Причина:** Это нормальное поведение v3.4

**Объяснение:** JVB API не отдаёт IP, только имена. Берётся последний IP из лога для комнаты.

---

## 📞 КОНТАКТЫ

**Администратор:** vardo001  
**Пароль SSH:** !P09710023p  
**Серверы:** 10.0.1.110, 10.0.1.130, 10.0.1.131, 10.0.1.132, 10.0.1.133

---

**ВЕРСИЯ ДОКУМЕНТАЦИИ:** 1.0  
**ДАТА СОЗДАНИЯ:** 26 Февраля 2026
