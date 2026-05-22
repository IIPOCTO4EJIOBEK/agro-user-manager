import flask
import subprocess
import json
import random
import time
import os
import threading
import sqlite3
import sys
from datetime import datetime, timedelta

app = flask.Flask(__name__)

CODE_TTL = 300
CLEANUP_INTERVAL = 60
SESSION_TTL = 86400
SPEED_LIMIT = "5M"
DB_PATH = "/opt/sms-auth/sms_auth.db"
MIKROTIK_IP = "10.5.24.150"
MIKROTIK_USER = "vardo001"
MIKROTIK_PASS = "!P09710023p"
HOME_RST_IP = "10.1.222.1"
HOME_RST_USER = "vardo001"
HOME_RST_PASS = "09710023p"
SMS_SCRIPT = "/usr/lib/zabbix/alertscripts/mikrotik_sms.sh"
CODES = {}


def init_db():
    os.makedirs(os.path.dirname(DB_PATH) or ".", exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.execute(
        "CREATE TABLE IF NOT EXISTS sms_auth_log (id INTEGER PRIMARY KEY AUTOINCREMENT, phone TEXT NOT NULL, mac TEXT, ip TEXT, code_sent INTEGER DEFAULT 0, code_verified INTEGER DEFAULT 0, authorized INTEGER DEFAULT 0, ts_sent TEXT, ts_verified TEXT, ts_authorized TEXT, user_agent TEXT, hotspot_name TEXT DEFAULT '', hotspot_gw TEXT DEFAULT '', hotspot_ap TEXT DEFAULT '')"
    )
    for col in ["hotspot_name", "hotspot_gw", "hotspot_ap"]:
        try:
            conn.execute(f"ALTER TABLE sms_auth_log ADD COLUMN {col} TEXT DEFAULT ''")
        except:
            pass
    conn.commit()
    conn.close()


MIKROTIK_HOTSPOT_IP = MIKROTIK_IP  # 10.5.24.150
HOTSPOT_AP = "wlan1 (Guest)"


def log_event(
    phone,
    mac=None,
    ip=None,
    event="sent",
    ua=None,
    hotspot_name="",
    hotspot_gw="",
    hotspot_ap="",
):
    try:
        conn = sqlite3.connect(DB_PATH)
        now = datetime.now().isoformat()
        if event == "sent":
            conn.execute(
                "INSERT INTO sms_auth_log (phone, mac, ip, code_sent, ts_sent, user_agent, hotspot_name, hotspot_gw, hotspot_ap) VALUES (?,?,?,1,?,?,?,?,?)",
                (
                    phone,
                    mac or "",
                    ip or "",
                    now,
                    ua or "",
                    hotspot_name or "",
                    hotspot_gw or "",
                    hotspot_ap or "",
                ),
            )
        elif event == "verified":
            conn.execute(
                "UPDATE sms_auth_log SET code_verified=1, ts_verified=?, hotspot_name=?, hotspot_gw=?, hotspot_ap=? WHERE phone=? AND ts_sent=(SELECT MAX(ts_sent) FROM sms_auth_log WHERE phone=?)",
                (
                    now,
                    hotspot_name or "",
                    hotspot_gw or "",
                    hotspot_ap or "",
                    phone,
                    phone,
                ),
            )
        elif event == "authorized":
            conn.execute(
                "UPDATE sms_auth_log SET authorized=1, ts_authorized=?, hotspot_name=?, hotspot_gw=?, hotspot_ap=? WHERE phone=? AND ts_verified=(SELECT MAX(ts_verified) FROM sms_auth_log WHERE phone=?)",
                (
                    now,
                    hotspot_name or "",
                    hotspot_gw or "",
                    hotspot_ap or "",
                    phone,
                    phone,
                ),
            )
        conn.commit()
        conn.close()
    except:
        pass


def run_mikrotik(cmd):
    result = subprocess.run(
        [
            "sshpass",
            "-p",
            MIKROTIK_PASS,
            "ssh",
            "-o",
            "StrictHostKeyChecking=no",
            "-o",
            "PreferredAuthentications=password",
            "-o",
            "PubkeyAuthentication=no",
            "-o",
            "ConnectTimeout=10",
            f"{MIKROTIK_USER}@{MIKROTIK_IP}",
            cmd,
        ],
        capture_output=True,
        text=True,
        timeout=20,
    )
    return result.returncode == 0, result.stdout, result.stderr


def send_sms(phone, message):
    try:
        result = subprocess.run(
            ["bash", SMS_SCRIPT, phone, "WiFi", message],
            capture_output=True,
            text=True,
            timeout=30,
        )
        return result.returncode == 0
    except:
        return False


def run_ssh_home(cmd):
    result = subprocess.run(
        [
            "sshpass",
            "-p",
            HOME_RST_PASS,
            "ssh",
            "-o",
            "StrictHostKeyChecking=no",
            "-o",
            "PreferredAuthentications=password",
            "-o",
            "PubkeyAuthentication=no",
            "-o",
            "ConnectTimeout=10",
            f"{HOME_RST_USER}@{HOME_RST_IP}",
            cmd,
        ],
        capture_output=True,
        text=True,
        timeout=15,
    )
    return result.returncode == 0, result.stdout, result.stderr


def get_mac_by_ip(ip):
    ok, out, _ = run_ssh_home(f"/ip dhcp-server lease print where address={ip}")
    if not ok:
        return None
    for line in out.split("\n"):
        if ip in line:
            parts = line.split()
            for p in parts:
                if ":" in p and len(p) == 17:
                    return p
    return None


def normalize_phone(p):
    p = "".join(c for c in p if c.isdigit() or c == "+")
    if not p:
        return ""
    if p.startswith("8") and len(p) == 11:
        p = "+7" + p[1:]
    elif p.startswith("7") and len(p) == 11:
        p = "+" + p
    elif not p.startswith("+"):
        p = "+" + p
    if not p.startswith("+7"):
        return ""
    if len(p) != 12:
        return ""
    return p


def authorize_mac(mac, phone):
    ts = str(int(time.time()))
    comment = f"sms_auth_{ts}_{phone}"
    ok1, _, _ = run_mikrotik(
        f"/ip hotspot ip-binding add mac-address={mac} type=bypassed comment={comment}"
    )
    ok2, _, _ = run_mikrotik(
        f"/queue simple add name=sms_{phone[-4:]} dst={mac}/32 max-limit={SPEED_LIMIT}/{SPEED_LIMIT} comment={comment}"
    )
    ok3, _, _ = run_ssh_home(
        f"/ip hotspot ip-binding add mac-address={mac} type=bypassed comment={comment}"
    )
    return ok1 or ok3


def cleanup_expired():
    now = int(time.time())
    for router, runner in [("mikrotik", run_mikrotik), ("home", run_ssh_home)]:
        ok, out, _ = runner("/ip hotspot ip-binding print without-paging")
        if not ok:
            continue
        for line in out.split("\n"):
            if "sms_auth_" not in line:
                continue
            parts = line.split()
            for p in parts:
                if p.startswith("sms_auth_"):
                    try:
                        ts = int(p.split("_")[2])
                        if now - ts > SESSION_TTL:
                            runner(
                                f'/ip hotspot ip-binding remove [find where comment~"sms_auth_{ts}"]'
                            )
                            runner(
                                f'/queue simple remove [find where comment~"sms_auth_{ts}"]'
                            )
                    except:
                        pass


LOGIN_PAGE = """<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>WiFi</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Arial,sans-serif;background:#f0f2f5;display:flex;justify-content:center;align-items:center;min-height:100vh}
.card{background:#fff;border-radius:12px;padding:32px;width:360px;max-width:90vw;box-shadow:0 2px 16px rgba(0,0,0,0.1);text-align:center}
.logo{font-size:28px;font-weight:bold;color:#1a73e8;margin-bottom:4px;letter-spacing:2px}
.subtitle{color:#666;margin-bottom:24px;font-size:14px}
.phone-wrap{display:flex;align-items:center;border:2px solid #ddd;border-radius:8px;margin-bottom:12px;overflow:hidden}
.phone-wrap:focus-within{border-color:#1a73e8}
.phone-prefix{background:#f5f5f5;padding:12px 8px;font-size:16px;font-weight:bold;color:#333;border-right:1px solid #ddd;white-space:nowrap}
.phone-wrap input{flex:1;border:none!important;padding:12px;font-size:16px;margin:0!important;text-align:left}
.phone-wrap input:focus{outline:none}
button{width:100%;padding:12px;background:#1a73e8;color:#fff;border:none;border-radius:8px;font-size:16px;font-weight:bold;cursor:pointer}
button:hover{background:#1557b0}
.error{color:#d32f2f;font-size:13px;margin-bottom:8px}
.checkbox-wrap{display:flex;align-items:center;justify-content:center;gap:8px;margin-bottom:16px;font-size:13px;color:#555}
.checkbox-wrap input[type=checkbox]{width:18px;height:18px;cursor:pointer}
</style>
</head>
<body>
<div class="card">
<div class="logo">Просторы</div>
<div class="subtitle">Гостевой WiFi</div>
"""

LOGIN_FORM = """<form action="/hotspot/login" method="POST">
<input type="hidden" name="ip" value="__IP__">
<input type="hidden" name="phone_prefix" value="+7">
<p style="margin-bottom:16px;color:#555">Телефон</p>
<div class="phone-wrap"><span class="phone-prefix">+7</span><input type="tel" name="phone_digits" placeholder="999 999-99-99" maxlength="10" required></div>
<div class="checkbox-wrap"><input type="checkbox" name="agree" value="1" required><span>Я согласен с правилами</span></div>
<button type="submit">Получить код</button>
__ERROR__
</form>
"""

LOGIN_FOOT = """</div>
</body>
</html>"""

VERIFY_PAGE_TOP = """<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>WiFi</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Arial,sans-serif;background:#f0f2f5;display:flex;justify-content:center;align-items:center;min-height:100vh}
.card{background:#fff;border-radius:12px;padding:32px;width:360px;max-width:90vw;box-shadow:0 2px 16px rgba(0,0,0,0.1);text-align:center}
.logo{font-size:28px;font-weight:bold;color:#1a73e8;margin-bottom:4px;letter-spacing:2px}
.subtitle{color:#666;margin-bottom:24px;font-size:14px}
input{width:100%;padding:12px;border:2px solid #ddd;border-radius:8px;font-size:16px;margin-bottom:12px;text-align:center}
input:focus{outline:none;border-color:#1a73e8}
button{width:100%;padding:12px;background:#1a73e8;color:#fff;border:none;border-radius:8px;font-size:16px;font-weight:bold;cursor:pointer}
button:hover{background:#1557b0}
.error{color:#d32f2f;font-size:13px;margin-bottom:8px}
.success{color:#388e3c;font-size:13px;margin-bottom:8px}
</style>
</head>
<body>
<div class="card">
<div class="logo">Просторы</div>
<div class="subtitle">Гостевой WiFi</div>
"""

VERIFY_FORM = """<form action="/hotspot/verify" method="POST">
<input type="hidden" name="phone" value="__PHONE__">
<input type="hidden" name="ip" value="__IP__">
<p style="margin-bottom:16px;color:#555">Введите код из SMS на __PHONE_MASK__</p>
<input type="text" name="code" placeholder="0000" maxlength="6" inputmode="numeric" required>
<button type="submit">Войти</button>
__MSG__
</form>
"""

VERIFY_FOOT = """</div>
</body>
</html>"""

SUCCESS_PAGE = """<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="refresh" content="3;url=http://1.1.1.1">
<title>WiFi</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Arial,sans-serif;background:#f0f2f5;display:flex;justify-content:center;align-items:center;min-height:100vh}
.card{background:#fff;border-radius:12px;padding:32px;text-align:center;box-shadow:0 2px 16px rgba(0,0,0,0.1);max-width:360px}
.check{color:#388e3c;font-size:48px;margin-bottom:16px}
h2{color:#333;margin-bottom:8px}
p{color:#666}
</style>
</head>
<body>
<div class="card">
<div class="logo" style="font-size:28px;font-weight:bold;color:#1a73e8;letter-spacing:2px;margin-bottom:12px">Просторы</div>
<div class="check">✓</div>
<h2>Доступ предоставлен</h2>
<p>Вы авторизованы. Можете пользоваться Интернетом.</p>
<p style="color:#999;font-size:12px;margin-top:12px">Сессия: 24ч · Скорость: 5 Мбит/с</p>
</div>
</body>
</html>"""


@app.route("/hotspot/login", methods=["GET", "POST"])
def hotspot_login():
    mac = flask.request.args.get("mac", "00:00:00:00:00:00")
    ip = flask.request.args.get("ip", "0.0.0.0")
    hotspot_name = flask.request.args.get("server", "hotspot-guest")
    hotspot_gw = flask.request.args.get("gw", MIKROTIK_HOTSPOT_IP)
    hotspot_ap = flask.request.args.get("ap", HOTSPOT_AP)

    if flask.request.method == "POST":
        if not flask.request.form.get("agree"):
            return (
                LOGIN_PAGE
                + LOGIN_FORM.replace("__IP__", ip).replace(
                    "__ERROR__", '<div class="error">Согласитесь с правилами</div>'
                )
                + LOGIN_FOOT
            )

        prefix = flask.request.form.get("phone_prefix", "+7")
        digits = flask.request.form.get("phone_digits", "")
        phone = normalize_phone(prefix + digits)
        ip = flask.request.form.get("ip", ip)
        mac_real = get_mac_by_ip(ip) or mac
        ua = flask.request.headers.get("User-Agent", "")

        if not phone:
            return (
                LOGIN_PAGE
                + LOGIN_FORM.replace("__IP__", ip).replace(
                    "__ERROR__",
                    '<div class="error">Только номера РФ (+7)</div>',
                )
                + LOGIN_FOOT
            )

        code = str(random.randint(1000, 9999))
        CODES[phone] = {
            "code": code,
            "mac": mac_real,
            "ip": ip,
            "time": time.time(),
            "hotspot_name": hotspot_name,
            "hotspot_gw": hotspot_gw,
            "hotspot_ap": hotspot_ap,
        }
        log_event(phone, mac_real, ip, "sent", ua, hotspot_name, hotspot_gw, hotspot_ap)

        ok = send_sms(phone, f"Kod dlya WiFi: {code}")

        phone_masked = phone[:3] + "***" + phone[-3:] if len(phone) > 6 else phone
        verify_form = (
            VERIFY_FORM.replace("__PHONE__", phone)
            .replace("__IP__", ip)
            .replace("__PHONE_MASK__", phone_masked)
        )

        if ok:
            verify_form = verify_form.replace(
                "__MSG__", '<div class="success">SMS отправлен</div>'
            )
        else:
            verify_form = verify_form.replace(
                "__MSG__", '<div class="error">Ошибка отправки SMS</div>'
            )

        return VERIFY_PAGE_TOP + verify_form + VERIFY_FOOT

    return (
        LOGIN_PAGE
        + LOGIN_FORM.replace("__IP__", ip).replace("__ERROR__", "")
        + LOGIN_FOOT
    )


@app.route("/hotspot/verify", methods=["GET", "POST"])
def hotspot_verify():
    phone = flask.request.args.get("phone", "") or flask.request.form.get("phone", "")
    ip = flask.request.args.get("ip", "") or flask.request.form.get("ip", "0.0.0.0")

    phone_masked = phone[:3] + "***" + phone[-3:] if len(phone) > 6 else phone
    verify_form = (
        VERIFY_FORM.replace("__PHONE__", phone)
        .replace("__IP__", ip)
        .replace("__PHONE_MASK__", phone_masked)
    )

    if flask.request.method == "POST":
        code = flask.request.form.get("code", "").strip()
        entry = CODES.get(phone)
        if not entry:
            return (
                VERIFY_PAGE_TOP
                + verify_form.replace(
                    "__MSG__", '<div class="error">Код не запрошен</div>'
                )
                + VERIFY_FOOT
            )
        if time.time() - entry["time"] > CODE_TTL:
            del CODES[phone]
            return (
                VERIFY_PAGE_TOP
                + verify_form.replace("__MSG__", '<div class="error">Код истек</div>')
                + VERIFY_FOOT
            )
        if entry["code"] != code:
            return (
                VERIFY_PAGE_TOP
                + verify_form.replace(
                    "__MSG__", '<div class="error">Неверный код</div>'
                )
                + VERIFY_FOOT
            )

        hotspot_name = entry.get("hotspot_name", "")
        hotspot_gw = entry.get("hotspot_gw", "")
        hotspot_ap = entry.get("hotspot_ap", "")
        log_event(
            phone,
            entry.get("mac", ""),
            ip,
            "verified",
            hotspot_name=hotspot_name,
            hotspot_gw=hotspot_gw,
            hotspot_ap=hotspot_ap,
        )
        mac = entry.get("mac", "")
        authorize_mac(mac, phone)
        log_event(
            phone,
            mac,
            ip,
            "authorized",
            hotspot_name=hotspot_name,
            hotspot_gw=hotspot_gw,
            hotspot_ap=hotspot_ap,
        )
        del CODES[phone]
        return SUCCESS_PAGE

    return VERIFY_PAGE_TOP + verify_form.replace("__MSG__", "") + VERIFY_FOOT


@app.route("/hotspot/status")
def hotspot_status():
    return SUCCESS_PAGE


@app.route("/")
def index():
    return flask.redirect("/hotspot/login?ip=0.0.0.0")


@app.route("/api/sms/request", methods=["POST"])
def api_sms_request():
    data = flask.request.get_json(silent=True) or {}
    phone = normalize_phone(data.get("phone", ""))
    mac = data.get("mac", "00:00:00:00:00:00")
    ip = data.get("ip", "0.0.0.0")
    hotspot_name = data.get("hotspot_name", "hotspot-guest")
    hotspot_gw = data.get("hotspot_gw", MIKROTIK_HOTSPOT_IP)
    hotspot_ap = data.get("hotspot_ap", HOTSPOT_AP)
    ua = flask.request.headers.get("User-Agent", "")
    if not phone:
        return flask.jsonify({"ok": False, "error": "Только номера РФ (+7)"})
    code = str(random.randint(1000, 9999))
    CODES[phone] = {
        "code": code,
        "mac": mac,
        "ip": ip,
        "time": time.time(),
        "hotspot_name": hotspot_name,
        "hotspot_gw": hotspot_gw,
        "hotspot_ap": hotspot_ap,
    }
    log_event(phone, mac, ip, "sent", ua, hotspot_name, hotspot_gw, hotspot_ap)
    ok = send_sms(phone, f"Kod dlya WiFi: {code}")
    return flask.jsonify({"ok": ok, "error": None if ok else "SMS error"})


@app.route("/api/sms/verify", methods=["POST"])
def api_sms_verify():
    data = flask.request.get_json(silent=True) or {}
    phone = normalize_phone(data.get("phone", ""))
    code = data.get("code", "").strip()
    entry = CODES.get(phone)
    if not entry:
        return flask.jsonify({"ok": False, "error": "No code"})
    if time.time() - entry["time"] > CODE_TTL:
        del CODES[phone]
        return flask.jsonify({"ok": False, "error": "Expired"})
    if entry["code"] != code:
        return flask.jsonify({"ok": False, "error": "Wrong code"})
    hotspot_name = entry.get("hotspot_name", "")
    hotspot_gw = entry.get("hotspot_gw", "")
    hotspot_ap = entry.get("hotspot_ap", "")
    log_event(
        phone,
        entry.get("mac", ""),
        entry.get("ip", ""),
        "verified",
        hotspot_name=hotspot_name,
        hotspot_gw=hotspot_gw,
        hotspot_ap=hotspot_ap,
    )
    authorize_mac(entry.get("mac", ""), phone)
    log_event(
        phone,
        entry.get("mac", ""),
        entry.get("ip", ""),
        "authorized",
        hotspot_name=hotspot_name,
        hotspot_gw=hotspot_gw,
        hotspot_ap=hotspot_ap,
    )
    del CODES[phone]
    return flask.jsonify({"ok": True})


@app.route("/api/sms-auth/reset", methods=["GET", "POST"])
def api_sms_reset():
    if flask.request.method == "GET":
        mac = flask.request.args.get("mac", "")
        phone = flask.request.args.get("phone", "")
    else:
        data = flask.request.get_json(silent=True) or {}
        mac = data.get("mac", "")
        phone = data.get("phone", "")
    if not mac and not phone:
        return flask.jsonify({"ok": False, "error": "mac or phone required"})
    results = []
    if mac:
        for runner, label in [(run_mikrotik, "wapR"), (run_ssh_home, "home")]:
            ok1, _, _ = runner(
                f'/ip hotspot ip-binding remove [find where mac-address="{mac}"]'
            )
            ok2, _, _ = runner(f'/queue simple remove [find where dst="{mac}/32"]')
            ok3, _, _ = runner(
                f'/ip hotspot active remove [find where mac-address="{mac}"]'
            )
            ok4, _, _ = runner(
                f'/ip hotspot host remove [find where mac-address="{mac}"]'
            )
            ok5, _, _ = runner(
                f'/ip dhcp-server lease remove [find where mac-address="{mac}"]'
            )
            results.append(
                {
                    "router": label,
                    "mac": mac,
                    "ip_binding": ok1,
                    "queue": ok2,
                    "kick": ok3,
                    "host": ok4,
                    "dhcp": ok5,
                }
            )
        if phone:
            conn = sqlite3.connect(DB_PATH)
            conn.execute(
                "UPDATE sms_auth_log SET authorized=0 WHERE phone=? AND authorized=1",
                (phone,),
            )
            conn.commit()
            conn.close()
    elif phone:
        conn = sqlite3.connect(DB_PATH)
        conn.execute(
            "UPDATE sms_auth_log SET authorized=0 WHERE phone=? AND authorized=1",
            (phone,),
        )
        conn.commit()
        conn.close()
    return flask.jsonify({"ok": True, "results": results})


@app.route("/api/sms-auth/history")
def sms_history():
    limit = flask.request.args.get("limit", 100, int)
    offset = flask.request.args.get("offset", 0, int)
    phone_filter = flask.request.args.get("phone", "")
    try:
        conn = sqlite3.connect(DB_PATH)
        query = "SELECT * FROM sms_auth_log"
        params = []
        if phone_filter:
            query += " WHERE phone LIKE ?"
            params.append("%" + phone_filter + "%")
        query += " ORDER BY id DESC LIMIT ? OFFSET ?"
        params.extend([limit, offset])
        rows = conn.execute(query, params).fetchall()
        total = conn.execute("SELECT COUNT(*) FROM sms_auth_log").fetchone()[0]
        conn.close()
        result = []
        for r in rows:
            result.append(
                {
                    "id": r[0],
                    "phone": r[1],
                    "mac": r[2],
                    "ip": r[3],
                    "code_sent": r[4],
                    "code_verified": r[5],
                    "authorized": r[6],
                    "ts_sent": r[7],
                    "ts_verified": r[8],
                    "ts_authorized": r[9],
                    "user_agent": r[10],
                    "hotspot_name": r[11] if len(r) > 11 else "",
                    "hotspot_gw": r[12] if len(r) > 12 else "",
                    "hotspot_ap": r[13] if len(r) > 13 else "",
                }
            )
        return flask.jsonify({"ok": True, "data": result, "total": total})
    except Exception as e:
        return flask.jsonify({"ok": False, "error": str(e)})


@app.route("/api/sms-auth/stats")
def sms_stats():
    try:
        conn = sqlite3.connect(DB_PATH)
        total = conn.execute("SELECT COUNT(*) FROM sms_auth_log").fetchone()[0]
        sent = conn.execute(
            "SELECT COUNT(*) FROM sms_auth_log WHERE code_sent=1"
        ).fetchone()[0]
        verified = conn.execute(
            "SELECT COUNT(*) FROM sms_auth_log WHERE code_verified=1"
        ).fetchone()[0]
        authorized = conn.execute(
            "SELECT COUNT(*) FROM sms_auth_log WHERE authorized=1"
        ).fetchone()[0]
        unique_phones = conn.execute(
            "SELECT COUNT(DISTINCT phone) FROM sms_auth_log"
        ).fetchone()[0]
        conn.close()
        return flask.jsonify(
            {
                "ok": True,
                "total": total,
                "sent": sent,
                "verified": verified,
                "authorized": authorized,
                "unique_phones": unique_phones,
            }
        )
    except Exception as e:
        return flask.jsonify({"ok": False, "error": str(e)})


def cleanup_loop():
    while True:
        time.sleep(CLEANUP_INTERVAL)
        now = int(time.time())
        for k in list(CODES.keys()):
            if now - CODES[k].get("time", 0) > CODE_TTL:
                del CODES[k]
        try:
            cleanup_expired()
        except:
            pass


if __name__ == "__main__":
    init_db()
    t = threading.Thread(target=cleanup_loop, daemon=True)
    t.start()
    app.run(host="0.0.0.0", port=5000, debug=False)
