#!/usr/bin/env node
/**
 * AD Ultimate Manager V3.1 — AH Prostory
 * =========================================
 * MEGA UPDATE — всё работает на 10.1.17.128
 * 
 * Исправления:
 *   ✅ WinRM/PS удалён → ldap CLI (ldapadd/ldapmodify) как в V1
 *   ✅ Все операции CREATE/UPDATE/ENABLE/DISABLE работают
 *   ✅ CSV импорт с авто-определением OU (7-шаговый поиск)
 *   ✅ Детальное логирование каждой операции
 *   ✅ SQLite аудит всех действий
 *   ✅ Русские сообщения об ошибках
 *   ✅ Batch toggle (массовое включение/отключение)
 *   ✅ Авто-фолбэк между 10.1.20.21 и 10.0.2.21
 */

const express = require('express');
const cors = require('cors');
const session = require('express-session');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
const { execSync } = require('child_process');
const ldap = require('ldapjs');
const fs = require('fs');
const path = require('path');
const iconv = require('iconv-lite');
const { parse } = require('csv-parse/sync');
const Database = require('better-sqlite3');

const app = express();
const PORT = process.env.PORT || 4003;

// ─── Безопасность ─────────────────────────────────────────────────
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({
    origin: [
        'http://10.1.17.128', 'http://10.1.17.128:80',
        'http://10.1.17.128:8080', 'http://10.1.17.128:8089',
        'http://localhost:8080', 'http://localhost:8089', 'http://localhost'
    ],
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.static('/opt/agro-user-manager-v3/frontend'));

app.use(session({
    secret: process.env.SESSION_SECRET || require('crypto').randomBytes(32).toString('hex'),
    resave: false,
    saveUninitialized: false,
    cookie: { secure: false, httpOnly: true, sameSite: 'lax', maxAge: 8 * 60 * 60 * 1000 }
}));

const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, max: 10,
    message: { error: 'Слишком много попыток. Попробуйте через 15 мин.' }
});
app.use('/auth/login', loginLimiter);

// ─── Константы ────────────────────────────────────────────────────
const BASE_DN = 'DC=rusagroeco,DC=ru'; 
const ROOT_DN = 'DC=rusagroeco,DC=ru';
const ENV = { ...process.env, LDAPTLS_REQCERT: 'never' };
const VPN_GROUP = 'CN=AD_VPN_Users,OU=Service Groups,OU=Groups,DC=rusagroeco,DC=ru';

// ─── SQLite Аудит ─────────────────────────────────────────────────
const AUDIT_DB = '/opt/agro-user-manager-v3/data/audit.db';
let audit;
try {
    audit = new Database(AUDIT_DB);
    audit.exec(`CREATE TABLE IF NOT EXISTS audit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts TEXT DEFAULT (datetime('now','localtime')),
        operator TEXT, action TEXT, target TEXT, details TEXT
    )`);
    audit.pragma('journal_mode=WAL');
} catch(e) { console.error('AUDIT DB ERROR:', e.message); }

function auditLog(operator, action, target, details) {
    try {
        const mskTs = mskISO().replace('T', ' ').substring(0, 19);
        if (audit) audit.prepare('INSERT INTO audit (ts, operator, action, target, details) VALUES (?,?,?,?,?)')
            .run(mskTs, operator || 'system', action, target, JSON.stringify(details || {}));
    } catch(e) { /* silently ignore audit failures */ }
}

// ─── Логирование ──────────────────────────────────────────────────
const MSK_OFFSET = 3 * 60 * 60 * 1000;
function mskISO() {
    return new Date(Date.now() + MSK_OFFSET).toISOString().replace('Z', '+03:00');
}
function log(level, msg, details) {
    const ts = mskISO();
    const detailStr = details ? ' | ' + JSON.stringify(details).substring(0, 1200) : '';
    const line = `${ts} [${level}] ${msg}${detailStr}`;
    console.log(line);
}

// ─── Утилиты ──────────────────────────────────────────────────────

function deepTrim(obj) {
    if (typeof obj !== 'object' || obj === null) return typeof obj === 'string' ? obj.trim() : obj;
    for (const key in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, key)) {
            obj[key] = deepTrim(obj[key]);
        }
    }
    return obj;
}

function escapeDN(val) {
    return (val || '').replace(/[\\,"+<>;#=]/g, '\\$&');
}

// Декодер LDAP escape-последовательностей в UTF-8 строку
function decodeEscapedUtf8DN(dn) {
    if (!dn || typeof dn !== 'string') return dn;
    return dn.replace(/((?:\\[0-9a-fA-F]{2})+)/g, (seq) => {
        const bytes = seq.split('\\').filter(Boolean).map(h => parseInt(h, 16));
        return Buffer.from(bytes).toString('utf8');
    });
}

// Экранирование значений для LDAP-фильтров
function escapeLDAPFilterValue(v) {
    return String(v || '')
        .replace(/\\/g, '\\5c')
        .replace(/\*/g, '\\2a')
        .replace(/\(/g, '\\28')
        .replace(/\)/g, '\\29')
        .replace(/\0/g, '\\00');
}

function sanitize(msg, pass) {
    if (!msg) return msg;
    let clean = msg;
    if (pass) {
        const escapedPass = pass.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        clean = clean.replace(new RegExp(escapedPass, 'g'), '********');
    }
    return clean.replace(/-w\s+"[^"]+"/g, '-w "********"').replace(/-w\s+'[^']+'/g, '-w "********"');
}

function toLdifBase64(val) {
    if (!val) return '';
    return Buffer.from(val).toString('base64');
}

function isBase64Needed(val) {
    return /[^\x00-\x7F]/.test(val);
}

function toLdif(attr, val) {
    if (val === undefined || val === null) return '';
    // unicodePwd must always be base64-encoded (binary attribute)
    if (attr === 'unicodePwd') return attr + ':: ' + val;
    if (isBase64Needed(val)) return attr + ':: ' + toLdifBase64(val);
    return attr + ': ' + val;
}

// Транслитерация (кириллица → латиница)
const TR_MAP = {
    'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','ё':'yo','ж':'zh','з':'z',
    'и':'i','й':'y','к':'k','л':'l','м':'m','н':'n','о':'o','п':'p','р':'r',
    'с':'s','т':'t','у':'u','ф':'f','х':'h','ц':'ts','ч':'ch','ш':'sh','щ':'shch',
    'ъ':'','ы':'y','ь':'','э':'e','ю':'yu','я':'ya'
};
function tr(s) {
    if (!s) return '';
    return s.toLowerCase().split('').map(c => c in TR_MAP ? TR_MAP[c] : c).join('');
}

// Аббревиатуры (для truncate 64 chars)
const ABBREV = [
    // Регионы/кластеры
    ['Ростовского кластера', 'РК'],
    ['Ростовской области', 'РО'],
    ['Республики Калмыкия', 'РК'],
    ['Республика Калмыкия', 'РК'],
    ['Краснодарского края', 'КК'],
    ['Краснодарского кластера', 'КК'],
    ['Ставропольского края', 'СК'],
    ['Ставропольского кластера', 'СК'],
    ['Воронежского кластера', 'ВК'],
    // Частые длинные словосочетания
    ['чрезвычайных ситуаций', 'ЧС'],
    ['информационно-технологической', 'ИТ'],
    ['информационно-технологического', 'ИТ'],
    ['информационно-технологических', 'ИТ'],
    ['информационно-технологический', 'ИТ'],
    ['информационно-технологическая', 'ИТ'],
    ['информационно-технологические', 'ИТ'],
    ['информационно-технологическому', 'ИТ'],
    ['экономической безопасности и противодействия коррупции', 'эконбезопасности и ПК'],
    ['экономической безопасности', 'эконбезопасности'],
    ['противодействия коррупции', 'ПК'],
    ['сельскохозяйствен', 'с/х'],
    ['недвижимым имуществом', 'недв.имуществом'],
    ['недвижимого имущества', 'недв.имущества'],
    ['персоналу и организационному развитию', 'персоналу и оргразвитию'],
    ['кадровому администрированию и воинскому учету', 'кадр. администрированию и ВУ'],
    ['внутренних коммуникаций и корпоративной культуры', 'внутр. коммуникаций и корпкультуры'],
    ['по техническому развитию и инфраструктуре', 'по техразвитию и инфраструктуре'],
    ['бухгалтерского учета и отчетности', 'бухучета и отчетности'],
    ['сервисного обслуживания и эксплуатации', 'сервисного обслуживания'],
    ['акционерно-инспекторского контроля', 'акц.-инспекторского контроля'],
    ['управлению проектами и бизнес-процессами', 'управлению проектами и БП'],
    ['правовым и корпоративным вопросам', 'правовым и корп. вопросам'],
];
function abbrev(s) {
    if (!s) return '';
    for (const [f, t] of ABBREV) s = s.replace(f, t);
    return s;
}

// Словарь точных сокращений должностей (полная → короткая, ≤64 симв.)
const TITLE_SHORT = {
    'Руководитель направления по налоговому учету Ростовского и Краснодарского кластера':
        'Руководитель направления налогового учета РК и КК',
    'Заместитель генерального директора по персоналу и организационному развитию':
        'Зам. гендиректора по персоналу и оргразвитию',
    'Ведущий менеджер по кадровому администрированию и воинскому учету':
        'Ведущий менеджер по кадр. администрированию и ВУ',
    'Руководитель отдела внутренних коммуникаций и корпоративной культуры':
        'Руководитель отдела внутр. коммуникаций и корпкультуры',
    'Заместитель руководителя отдела экономической безопасности и противодействия коррупции':
        'Зам. руководителя отдела эконбезопасности и ПК',
    'Заместитель директора по техническому развитию и инфраструктуре по автоматизации процессов':
        'Зам. директора по техразвитию и автоматизации',
    'заместитель директора по техническому развитию и инфраструктуре по автоматизации процессов':
        'Зам. директора по техразвитию и автоматизации',
    'Руководитель отдела бухгалтерского учета и отчетности Ставропольского кластера':
        'Руководитель отдела бухучета и отчетности СК',
    'Заместитель руководителя службы безопасности объектов и персонала':
        'Зам. руководителя службы безопасности объектов',
    'Руководитель отдела по управлению недвижимым имуществом Ставропольского края':
        'Руководитель отдела управления недвижимостью СК',
    'Руководитель отдела по управлению недв.имуществом Ставропольского края':
        'Руководитель отдела управления недвижимостью СК',
    'Заместитель генерального директора по научным разработкам и цифровизации':
        'Зам. гендиректора по научным разработкам и цифровизации',
    'Заместитель директора по техническому развитию и инфраструктуре по ремонту и эксплуатации подвижного состава':
        'Зам. директора по техразвитию — ремонт и эксплуатация ПС',
    'Руководитель направления по внутреннему контролю в области земельных отношений':
        'Руководитель направления внутр. контроля земельных отношений',
};

// Умное сокращение: словарь → abbrev (только если >64) → truncate 64
function smartTitle(s) {
    if (!s) return '';
    // 1) Точное совпадение по словарю (применяется всегда)
    if (TITLE_SHORT[s]) return TITLE_SHORT[s];
    // 2) Если влазит в 64 — не сокращаем
    if (s.length <= 64) return s;
    // 3) Аббревиатуры — только для длинных строк
    let shortened = abbrev(s);
    // 4) Truncate до 64
    if (shortened.length > 64) shortened = shortened.substring(0, 64);
    return shortened;
}

// Универсальный t64: title/department/company/city — атрибуты AD ≤64 символов
function t64(s) { return smartTitle(s || ''); }

// ─── Auth Middleware ───────────────────────────────────────────────
function isAuth(req, res, next) {
    if (req.session?.authenticated) return next();
    res.status(401).json({ error: 'Требуется авторизация' });
}

// ─── Кэш AD ───────────────────────────────────────────────────────
let cache = {
    users: [], ous: [], groups: [], depts: [], comps: [], titles: [],
    locations: [], offices: [], descriptions: [], assistants: [],
    dbStats: {}, syncing: false, lastUpdate: 0
};

// ─── Быстрый поиск DN через CLI (единый клиент с ldapmodify) ──────
function ldapSearchCLI(session, filter) {
    const pwdFile = createPasswordFile(session);
    try {
        const cmd = `ldapsearch -x -C -H ${session.adUrl} -D "${session.adUser}" -y ${pwdFile} -b "${BASE_DN}" "${filter}" dn -LLL 2>&1`;
        const out = execSync(cmd, { encoding: 'utf-8', timeout: 10000, env: ENV }).trim();
        const dns = out.split('\n').filter(l => l.startsWith('dn: ')).map(l => l.substring(4).trim());
        return dns;
    } catch(e) {
        return [];
    } finally {
        try { fs.unlinkSync(pwdFile); } catch(e) {}
    }
}

// ─── Асинхронный сбор данных AD (ldapjs search) ───────────────────
function ldapSearchAsync(adUrl, adUser, adPass, base, filter, attrs) {
    return new Promise((resolve, reject) => {
        const client = ldap.createClient({ url: adUrl, tlsOptions: { rejectUnauthorized: false } });
        const results = [];
        client.bind(adUser, adPass, (err) => {
            if (err) { client.destroy(); return reject(err); }
            const opts = { filter, scope: 'sub', attributes: attrs, paged: { pageSize: 1000 } };
            client.search(base, opts, (err2, res) => {
                if (err2) { client.destroy(); return reject(err2); }
                res.on('searchEntry', (entry) => {
                    const obj = { dn: entry.pojo?.objectName || '' };
                    for (const attr of entry.pojo?.attributes || []) {
                        obj[attr.type] = attr.values?.[0] || '';
                    }
                    results.push(obj);
                });
                res.on('end', () => { client.unbind(); resolve(results); });
                res.on('error', (e) => { client.destroy(); reject(e); });
            });
        });
    });
}

async function getADData(user, pass, adUrl) {
    cache.syncing = true;
    log('INFO', 'AD SCAN: Запуск асинхронного сканирования...');
    const startTime = Date.now();
    try {
        const attrs = [
            'sAMAccountName', 'mail', 'displayName', 'department', 'company',
            'title', 'l', 'st', 'manager', 'info', 'telephoneNumber', 'mobile',
            'homePhone', 'extensionAttribute1', 'extensionAttribute2', 'extensionAttribute3',
            'assistant', 'userAccountControl', 'physicalDeliveryOfficeName',
            'description', 'homeMDB', 'memberOf', 'sn', 'givenName'
        ];

        const users = await ldapSearchAsync(adUrl, user, pass, BASE_DN,
            "(&(objectClass=user)(objectCategory=person))",
            attrs);

        const ous = await ldapSearchAsync(adUrl, user, pass, BASE_DN,
            '(objectClass=organizationalUnit)', ['ou', 'description']);

        const groups = await ldapSearchAsync(adUrl, user, pass, BASE_DN,
            '(objectClass=group)', ['cn', 'description']);

        const depts = new Set(), comps = new Set(), titles = new Set();
        const locs = new Set(), offices = new Set(), descs = new Set(), assts = new Set();
        const dbStats = {};
        for (let i = 1; i <= 12; i++) dbStats['DB' + String(i).padStart(2, '0')] = 0;

        for (const u of users) {
            // Декодируем CN из DN для фронтенда
            try {
                const rawCN = (u.dn || '').split(',')[0].replace(/^CN=/i, '').trim();
                u.cn = decodeEscapedUtf8DN(rawCN);
            } catch(e) { u.cn = (u.dn||'').split(',')[0].replace(/^CN=/i,''); }
            if (u.department) depts.add(u.department);
            if (u.company) comps.add(u.company);
            if (u.title) titles.add(u.title);
            if (u.l) locs.add(u.l);
            if (u.physicalDeliveryOfficeName) offices.add(u.physicalDeliveryOfficeName);
            if (u.description) descs.add(u.description);
            if (u.assistant) assts.add(u.assistant);
            if (u.homeMDB) {
                const m = u.homeMDB.match(/CN=(DB\d{2})/i);
                if (m && dbStats[m[1]] !== undefined) dbStats[m[1]]++;
            }
        }

        const ouList = ous.map(o => ({
            name: o.ou || 'OU',
            dn: o.dn || '',
            desc: o.description || ''
        })).filter(o => o.dn);

        const groupList = groups.map(g => ({
            name: g.cn || 'Group',
            dn: g.dn || '',
            desc: g.description || ''
        })).filter(g => g.dn);

        cache = {
            users: users.sort((a, b) => (a.displayName || '').localeCompare(b.displayName || '')),
            ous: ouList.sort((a, b) => a.dn.length - b.dn.length),
            groups: groupList.sort((a, b) => (a.name || '').localeCompare(b.name || '')),
            depts: Array.from(depts).sort(),
            comps: Array.from(comps).sort(),
            titles: Array.from(titles).sort(),
            locations: Array.from(locs).sort(),
            offices: Array.from(offices).sort(),
            descriptions: Array.from(descs).sort(),
            assistants: Array.from(assts).sort(),
            dbStats, syncing: false, lastUpdate: Date.now()
        };

        const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
        log('OK', `AD SCAN: Завершён. Пользователей: ${users.length}, Групп: ${groupList.length}, OU: ${ouList.length} (${elapsed}с)`);
    } catch (e) {
        cache.syncing = false;
        log('ERROR', 'AD SCAN: ' + sanitize(e.message, pass));
    }
}

// ─── Резолвинг manager DN (свежий поиск, а не из кэша) ──────────────
async function resolveManagerDN(session, managerValue) {
    if (!managerValue || /^ваканс|^vacanc/i.test(managerValue)) return null;

    // Если уже DN
    if (/^CN=/i.test(managerValue) || /,OU=/i.test(managerValue)) {
        return decodeEscapedUtf8DN(managerValue);
    }

    const safe = escapeLDAPFilterValue(managerValue);

    // 1. По displayName
    let found = await ldapSearchAsync(
        session.adUrl, session.adUser, session.adPass, BASE_DN,
        `(&(objectClass=user)(objectCategory=person)(displayName=${safe}))`,
        ['dn', 'sAMAccountName', 'displayName']
    );
    if (found?.[0]?.dn) return decodeEscapedUtf8DN(found[0].dn);

    // 2. По sAMAccountName
    found = await ldapSearchAsync(
        session.adUrl, session.adUser, session.adPass, BASE_DN,
        `(&(objectClass=user)(objectCategory=person)(sAMAccountName=${safe}))`,
        ['dn', 'sAMAccountName', 'displayName']
    );
    if (found?.[0]?.dn) return decodeEscapedUtf8DN(found[0].dn);

    // 3. По cache как fallback (точное совпадение, при дубликатах — приоритет не-стажёру)
    let mgrObj = cache.users.find(u =>
        u.sAMAccountName === managerValue ||
        u.dn === managerValue
    );
    // По displayName — возможны дубликаты
    if (!mgrObj?.dn && managerValue) {
        const candidates = cache.users.filter(u => u.displayName === managerValue && u.dn);
        if (candidates.length === 1) {
            mgrObj = candidates[0];
        } else if (candidates.length > 1) {
            // Приоритет: не стажёр + логин длиннее (основной, не клон)
            candidates.sort((a, b) => {
                const aIntern = /стаж[её]р/i.test(a.title || '') ? 1 : 0;
                const bIntern = /стаж[её]р/i.test(b.title || '') ? 1 : 0;
                if (aIntern !== bIntern) return aIntern - bIntern;
                return (b.sAMAccountName || '').length - (a.sAMAccountName || '').length;
            });
            mgrObj = candidates[0];
            log('INFO', `MANAGER duplicate pick: ${managerValue} → ${mgrObj.sAMAccountName} (из ${candidates.length})`);
        }
    }
    if (mgrObj?.dn) {
        if (/стаж[её]р/i.test(mgrObj.title || '')) {
            log('WARN', `MANAGER IS INTERN: ${managerValue} (${mgrObj.title}) — skipping`);
            return null;
        }
        return decodeEscapedUtf8DN(mgrObj.dn);
    }

    // 4. Нечёткий поиск: Фамилия совпадает + Имя начинается одинаково (≥3 общих символов)
    const parts = managerValue.trim().split(/\s+/);
    if (parts.length >= 2) {
        const lastName = parts[0].toLowerCase();
        const firstName = parts[1].toLowerCase();
        mgrObj = cache.users.find(u => {
            const dp = (u.displayName || '').toLowerCase().split(/\s+/);
            if (dp[0] !== lastName || dp.length < 2) return false;
            const adFirstName = dp[1];
            let matchLen = 0;
            while (matchLen < firstName.length && matchLen < adFirstName.length && firstName[matchLen] === adFirstName[matchLen]) {
                matchLen++;
            }
            return matchLen >= 3; // минимум 3 общих символа
        });
        if (mgrObj?.dn) {
            log('INFO', `MANAGER fuzzy match: ${managerValue} → ${mgrObj.displayName}`);
            // Авто-исправление имени менеджера в AD
            if (mgrObj.displayName !== managerValue) {
                const decodedMgrDn = decodeEscapedUtf8DN(mgrObj.dn);
                try {
                    ldapModifyCLI(session, decodedMgrDn, [
                        { operation: 'replace', modification: { displayName: managerValue } }
                    ]);
                    log('OK', `MANAGER NAME FIXED: ${mgrObj.displayName} → ${managerValue}`);
                    mgrObj.displayName = managerValue; // update cache
                } catch (fixErr) {
                    log('WARN', `MANAGER NAME FIX FAILED: ${mgrObj.displayName} → ${managerValue}: ${fixErr.message}`);
                }
            }
            return decodeEscapedUtf8DN(mgrObj.dn);
        }
    }

    log('WARN', `MANAGER resolve FAILED: "${managerValue}" — не найден ни по LDAP, ни в кэше`);
    return null;
}

// ─── LDAP modify через ldapjs (для UPDATE — тот же клиент, что и кэш) ──
async function ldapModifyJS(session, dn, changes) {
    return new Promise((resolve, reject) => {
        const client = ldap.createClient({ url: session.adUrl, tlsOptions: { rejectUnauthorized: false } });
        client.bind(session.adUser, session.adPass, (err) => {
            if (err) { client.destroy(); return reject(err); }
            // Build array of { attr, values, op } for serial modification
            const mods = [];
            for (const c of changes) {
                const mod = c.modification || {};
                const op = c.operation || 'replace';
                for (const [attr, val] of Object.entries(mod)) {
                    const isEmpty = (val === '' || val === null || val === undefined);
                    mods.push({
                        attr: new ldap.Attribute({ type: attr, values: isEmpty ? [] : [String(val)] }),
                        op: op === 'delete' ? 'delete' : (isEmpty ? 'replace' : op)
                    });
                }
            }
            if (mods.length === 0) { client.unbind(); return resolve(); }
            // Serialize modifications: do one at a time
            function apply(idx) {
                if (idx >= mods.length) { client.unbind(); return resolve(); }
                try {
                    const m = mods[idx];
                    const change = new ldap.Change({ operation: m.op, modification: m.attr });
                    client.modify(dn, change, (e) => {
                        if (e) { client.unbind(); return reject(e); }
                        apply(idx + 1);
                    });
                } catch (err) {
                    client.unbind();
                    reject(err);
                }
            }
            apply(0);
        });
    });
}

// ─── LDAP CLI операции (ЗАМЕНА WinRM) ────────────────────────────
function createPasswordFile(session) {
    const pwdFile = '/tmp/adpwd_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8);
    fs.writeFileSync(pwdFile, session.adPass, { mode: 0o600 });
    return pwdFile;
}

function ldapModifyCLI(session, dn, changes) {
    const pwdFile = createPasswordFile(session);
    try {
        let ldif = "";
        if (isBase64Needed(dn)) {
            ldif = `dn:: ${toLdifBase64(dn)}\nchangetype: modify\n`;
        } else {
            ldif = `dn: ${dn}\nchangetype: modify\n`;
        }
        for (const change of changes) {
            const op = change.operation || 'replace';
            const mod = change.modification || {};
            for (const [attr, val] of Object.entries(mod)) {
                if (op === 'delete') {
                    ldif += `delete: ${attr}\n-\n`;
                } else if (val === '' || val === null || val === undefined) {
                    ldif += `replace: ${attr}\n-\n`;
                } else if (op === 'add') {
                    ldif += `add: ${attr}\n${toLdif(attr, val)}\n-\n`;
                } else {
                    ldif += `replace: ${attr}\n${toLdif(attr, val)}\n-\n`;
                }
            }
        }
        const lf = '/tmp/ldapmod_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8) + '.ldif';
        fs.writeFileSync(lf, ldif);

        const cmd = `ldapmodify -x -o referrals=on -H ${session.adUrl} -D "${session.adUser}" -y ${pwdFile} -f ${lf} 2>&1`;
        log('DEBUG', 'ldapmodify', { dn, changes: changes.length, cmd: cmd.substring(0, 120) });

        try { const out = execSync(cmd, { encoding: 'utf-8', timeout: 15000, env: ENV }); if (out.trim()) log('DEBUG', 'ldapmodify output', { out: out.substring(0, 200) }); return out; } catch(e) { const errOut = (e.stdout || "") + (e.stderr || ""); log("ERROR", "LDAP FAIL OUTPUT", {out: errOut, ldif: ldif.substring(0, 300)}); throw new Error(errOut || e.message); }
        if (out.trim()) log('DEBUG', 'ldapmodify output', { out: out.substring(0, 200) });
        try { fs.unlinkSync(lf); } catch(e) {}
        return out;
    } finally {
        try { fs.unlinkSync(pwdFile); } catch(e) {}
    }
}

function ldapAddCLI(session, dn, entry) {
    const pwdFile = createPasswordFile(session);
    try {
        let ldif = `dn: ${dn}\n`;
        const objClasses = entry.objectClass || ['top', 'person', 'organizationalPerson', 'user'];
        for (const oc of objClasses) ldif += `objectClass: ${oc}\n`;

        const skipKeys = ['objectClass', 'password', 'addVpn', 'createMail', 'exchDb', 'siteOU', 'userAccountControl'];
        for (const [k, v] of Object.entries(entry)) {
            if (skipKeys.includes(k)) continue;
            if (v === undefined || v === null || v === '') continue;
            ldif += `${toLdif(k, v)}\n`;
        }
        // userAccountControl is set via ldapmodify after creation (AD rejects it in ldapadd)

        const lf = '/tmp/ldapadd_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8) + '.ldif';
        fs.writeFileSync(lf, ldif);

        const cmd = `ldapadd -x -o referrals=on -H ${session.adUrl} -D "${session.adUser}" -y ${pwdFile} -f ${lf} 2>&1`;
        log('DEBUG', 'ldapadd', { dn, cmd: cmd.substring(0, 120) });

        try { const out = execSync(cmd, { encoding: 'utf-8', timeout: 15000, env: ENV }); if (out.trim()) log('DEBUG', 'ldapmodify output', { out: out.substring(0, 200) }); return out; } catch(e) { const errOut = (e.stdout || "") + (e.stderr || ""); log("ERROR", "LDAP FAIL OUTPUT", {out: errOut, ldif: ldif.substring(0, 300)}); throw new Error(errOut || e.message); }
        if (out.trim()) log('DEBUG', 'ldapadd output', { out: out.substring(0, 200) });
        try { fs.unlinkSync(lf); } catch(e) {}
        return out;
    } finally {
        try { fs.unlinkSync(pwdFile); } catch(e) {}
    }
}

// ─── Поиск OU для CSV импорта ────────────────────────────────────
const CITY_REGION = {
    'ростов': 'RND', 'ставропол': 'STV', 'краснодар': 'KRD',
    'москва': 'MSK', 'воронеж': 'VRN', 'нижн': 'NIZ', 'новгород': 'NIZ',
    'волгоград': 'VLC', 'белгород': 'BDN', 'липецк': 'LPK',
};

function getParentDN(dn) {
    const parts = dn.split(',').map(p => p.trim());
    return parts.slice(1).join(',');
}

function ouExists(dn) {
    return cache.ous && cache.ous.some(o => o.dn === dn);
}

function findSiteOU(city, comp, reg, dept) {
    if (!cache.ous || !cache.ous.length) return '';

    // 1) Определяем код региона по городу (приоритет) или региону
    let code = '';
    if (city) {
        const c = city.toLowerCase();
        for (const [k, v] of Object.entries(CITY_REGION)) {
            if (c.includes(k)) { code = v; break; }
        }
    }
    if (!code && reg) {
        const r = reg.toLowerCase();
        for (const [k, v] of Object.entries(CITY_REGION)) {
            if (r.includes(k)) { code = v; break; }
        }
    }

    if (code) {
        // 2) Ищем пользователя в ЭТОМ регионе с таким же отделом
        if (dept && cache.users?.length) {
            const sameDeptInRegion = cache.users.find(u =>
                u.department === dept && u.dn &&
                u.dn.toUpperCase().includes('OU=' + code)
            );
            if (sameDeptInRegion) {
                const parent = getParentDN(sameDeptInRegion.dn);
                if (ouExists(parent)) return parent;
            }
        }

        // 3) Самый частый parent OU в этом регионе (только существующие OU)
        if (cache.users?.length) {
            const regionUsers = cache.users.filter(u =>
                u.dn && u.dn.toUpperCase().includes('OU=' + code)
            );
            if (regionUsers.length > 0) {
                const parentCounts = {};
                for (const u of regionUsers) {
                    const p = getParentDN(u.dn);
                    if (ouExists(p)) {
                        parentCounts[p] = (parentCounts[p] || 0) + 1;
                    }
                }
                const sorted = Object.entries(parentCounts).sort((a, b) => b[1] - a[1]);
                if (sorted.length > 0) return sorted[0][0];
            }
        }

        // 4) OU=Users под регионом
        const userOU = cache.ous.find(o =>
            o.dn.toUpperCase().includes('OU=USERS') &&
            o.dn.toUpperCase().includes('OU=' + code)
        );
        if (userOU) return userOU.dn;

        // 5) Любой OU с кодом региона
        const match = cache.ous.find(o => o.dn.toUpperCase().includes('OU=' + code));
        if (match) return match.dn;
    }

    // 6) Прямой поиск по названию города/компании/региона
    if (city) {
        const match = cache.ous.find(o =>
            o.name === city || o.dn.toLowerCase().includes('ou=' + city.toLowerCase().replace(/\s/g, '') + ',')
        );
        if (match) return match.dn;
    }
    if (comp) {
        const match = cache.ous.find(o =>
            o.name === comp || o.dn.toLowerCase().includes('ou=' + comp.toLowerCase().replace(/\s/g, '') + ',')
        );
        if (match) return match.dn;
    }
    if (reg) {
        const match = cache.ous.find(o =>
            o.name === reg || o.dn.toLowerCase().includes('ou=' + reg.toLowerCase().replace(/\s/g, '') + ',')
        );
        if (match) return match.dn;
    }

    return '';
}

// ═══════════════════════════════════════════════════════════════════
//                            ROUTES
// ═══════════════════════════════════════════════════════════════════

// ─── AUTH ─────────────────────────────────────────────────────────
app.post('/auth/login', (req, res) => {
    let { username, password, adIp } = req.body;
    const adUser = username.includes('@') ? username : username + '@rusagroeco.ru';

    // Авто-фолбэк: пробуем оба DC
    const dcIPs = [adIp || '10.1.20.21', '10.0.2.21'].filter((v, i, a) => a.indexOf(v) === i);
    let lastError = '';

    const tryLogin = (idx) => {
        if (idx >= dcIPs.length) {
            log('ERROR', `LOGIN FAILED: ${adUser} — все DC отклонены`);
            return res.status(401).json({ error: 'Неверный логин/пароль или сервер недоступен' });
        }

        const adUrl = 'ldaps://' + dcIPs[idx];
        log('INFO', `LOGIN: попытка ${adUser} → ${adUrl}`);

        const client = ldap.createClient({ url: adUrl, tlsOptions: { rejectUnauthorized: false } });
        client.bind(adUser, password, (err) => {
            if (err) {
                lastError = err.message;
                log('WARN', `LOGIN: ${adUrl} → ${sanitize(err.message, password)}`);
                client.destroy();
                return tryLogin(idx + 1); // пробуем следующий DC
            }
            log('OK', `LOGIN SUCCESS: ${adUser} → ${adUrl}`);
            req.session.authenticated = true;
            req.session.adUser = adUser;
            req.session.adPass = password;
            req.session.adUrl = adUrl;
            req.session.username = username;
            client.unbind();
            auditLog(username, 'LOGIN', 'session', { ip: req.ip, server: dcIPs[idx] });
            // Загружаем AD сразу, потом отвечаем
            getADData(adUser, password, adUrl).then(() => {
                res.json({ success: true, server: dcIPs[idx] });
            }).catch(() => {
                res.json({ success: true, server: dcIPs[idx], warning: 'AD scan delayed' });
            });
        });
    };

    tryLogin(0);
});

app.get('/auth/check', (req, res) => {
    res.json({ authenticated: !!req.session?.authenticated });
});

app.post('/auth/logout', (req, res) => {
    const user = req.session?.username || 'unknown';
    req.session.destroy(() => {
        log('INFO', `LOGOUT: ${user}`);
        res.json({ success: true });
    });
});

// ─── DATA ─────────────────────────────────────────────────────────
app.get('/api/debug-dump', (req, res) => { res.json(cache.users.map(u => ({ sam: u.sAMAccountName, name: u.displayName, uac: u.userAccountControl }))); });

app.get('/api/debug-user/:q', isAuth, (req, res) => {
    const q = String(req.params.q || '').toLowerCase();
    res.json(cache.users.filter(u =>
        (u.displayName || '').toLowerCase().includes(q) ||
        (u.sAMAccountName || '').toLowerCase().includes(q)
    ));
});

app.get('/api/data', isAuth, (req, res) => {
    log('DEBUG', `GET /api/data: users=${cache.users.length}, ous=${cache.ous.length}, syncing=${cache.syncing}`);
    res.json(cache);
});

// ─── RESYNC (force AD reload) ─────────────────────────────────
app.post('/api/resync', isAuth, async (req, res) => {
    log('INFO', 'RESYNC: принудительная перезагрузка из AD');
    try {
        await getADData(req.session.adUser, req.session.adPass, req.session.adUrl);
        res.json({ success: true, users: cache.users.length, ous: cache.ous.length });
    } catch(e) {
        res.status(500).json({ success: false, error: sanitize(e.message, req.session.adPass) });
    }
});

// ─── OU LIST (for import dropdown) ──────────────────────────────
app.get('/api/ous', isAuth, (req, res) => {
    // Group OUs by region code extracted from DN
    const byRegion = {};
    for (const o of (cache.ous || [])) {
        const dn = o.dn.toUpperCase();
        // Extract region code from DN: OU=RND, OU=STV, etc.
        const parts = dn.split(',');
        let region = 'OTHER';
        for (const p of parts) {
            const trimmed = p.trim();
            if (trimmed.startsWith('OU=') && ['RND','STV','KRD','MSK','NIZ','VRN','VLC','BDN','LPK'].includes(trimmed.substring(3))) {
                region = trimmed.substring(3);
                break;
            }
        }
        if (!byRegion[region]) byRegion[region] = [];
        // Only include user OUs (containing OU=Users or similar)
        if (dn.includes('OU=USERS') || dn.includes('OU=Users')) {
            byRegion[region].push({ name: o.name, dn: o.dn });
        }
    }
    // Sort each region's OUs by name
    for (const r of Object.keys(byRegion)) {
        byRegion[r].sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    }
    res.json({ regions: byRegion, all: (cache.ous || []).filter(o => {
        const dn = o.dn.toUpperCase();
        return dn.includes('OU=USERS') || dn.includes('OU=Users');
    }).map(o => ({ name: o.name, dn: o.dn })) });
});

// ─── CREATE USER ──────────────────────────────────────────────────
app.post('/api/create-user', isAuth, [
    body('displayName').trim().notEmpty().withMessage('ФИО обязательно'),
    body('siteOU').trim().notEmpty().withMessage('Подразделение (OU) обязательно'),
], async (req, res) => {
    req.body = deepTrim(req.body);
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        log('WARN', 'CREATE: валидация не пройдена', errors.array());
        return res.status(400).json({ success: false, error: errors.array()[0].msg });
    }

    const d = req.body;
    const parts = (d.displayName || '').trim().split(/\s+/);
    const sn = (d.sn || parts[0] || '').trim();
    const gn = (d.givenName || parts[1] || '').trim();
    const pn = (d.patronymic || parts[2] || '').trim();

    const trSn = tr(sn).replace(/^./, c => c.toUpperCase());
    const trGn = tr(gn).replace(/^./, c => c.toUpperCase());
    let login = (d.sam || (tr(sn) + '.' + (tr(gn)[0] || '') + (tr(pn)[0] || '')).toLowerCase().replace(/[^a-z0-9.]/g, '')).trim();

    const t64 = (s) => smartTitle(s || '');

    const siteOU = d.siteOU.toUpperCase().startsWith('OU=USERS,') ? d.siteOU : `OU=Users,${d.siteOU}`;
    const cnLatin = `${trSn} ${trGn}`.trim();
    const userDN = `CN=${escapeDN(cnLatin)},${siteOU}`;
    const pass = d.password || `Agro${Math.random().toString(36).substring(2, 10)}!`;

    log('INFO', `CREATE: ${d.displayName} → login=${login}, OU=${siteOU}`);

    try {
        // Проверка уникальности логина и имени
        const existingLogin = cache.users.find(u => u.sAMAccountName === login);
        if (existingLogin) {
            log('WARN', `CREATE: логин ${login} уже занят (${existingLogin.displayName})`);
            return res.status(400).json({
                success: false,
                error: `Логин ${login} уже занят пользователем: ${existingLogin.displayName || existingLogin.sAMAccountName}`
            });
        }
        
        // Проверка по displayName (Клон-контроль)
        const sameNameUsers = cache.users.filter(u => u.displayName === d.displayName);
        if (sameNameUsers.length > 0) {
            // Проверяем дату рождения
            const clone = sameNameUsers.find(u => u.info && d.info && u.info.replace(/[.\/]/g, '') === d.info.replace(/[.\/]/g, ''));
            if (clone) {
                log('WARN', `CREATE: клон обнаружен (ФИО + Дата рождения совпали): ${d.displayName}`);
                return res.status(400).json({
                    success: false,
                    error: `Сотрудник "${d.displayName}" с датой рождения ${d.info} уже существует (логин: ${clone.sAMAccountName})`
                });
            }
            // Если дата рождения разная, разрешаем, но предупреждаем
            log('INFO', `CREATE: разрешено создание однофамильца (другая дата рождения): ${d.displayName}`);
        }

        // Формируем entry для ldapadd
        const entry = {
            cn: cnLatin,
            displayName: d.displayName,
            sn: trSn,
            givenName: trGn,
            sAMAccountName: login,
            userPrincipalName: login + '@ahprostory.ru',
            objectClass: ['top', 'person', 'organizationalPerson', 'user'],
            title: t64(d.title),
            department: t64(d.department),
            company: t64(d.company),
            l: t64(d.l),
            st: d.st,
            mail: (d.mail && d.mail !== '0') ? d.mail : (login + '@ahprostory.ru'),
            telephoneNumber: d.telephoneNumber,
            mobile: d.mobile,
            homePhone: d.homePhone,
            extensionAttribute1: sn,
            extensionAttribute2: gn,
            extensionAttribute3: pn,
            assistant: d.assistant,
            description: d.description,
            physicalDeliveryOfficeName: t64(d.office),
            info: d.info
            // userAccountControl set via ldapmodify after creation
        };

        // Чистим пустые поля
        for (const [k, v] of Object.entries(entry)) {
            if (v === undefined || v === null || v === '') delete entry[k];
        }

        // Менеджер
        if (d.manager && !/^ваканс|^vacanc/i.test(d.manager)) {
            const mgrObj = cache.users.find(u => u.displayName === d.manager || u.dn === d.manager);
            if (mgrObj?.dn) entry.manager = mgrObj.dn;
        }

        // 1) Создаём пользователя
        ldapAddCLI(req.session, userDN, entry);
        log('OK', `CREATE: пользователь ${login} создан в AD`);

        // 2) Ждём репликацию и устанавливаем пароль
        await new Promise(r => setTimeout(r, 1500));
        const pwdBase64 = Buffer.from(`"${pass}"`, 'utf16le').toString('base64');
        try {
            ldapModifyCLI(req.session, userDN, [
                { operation: 'replace', modification: { unicodePwd: pwdBase64 } }
            ]);
            log('OK', `CREATE: пароль установлен для ${login}`);
        } catch(e) {
            log('ERROR', `CREATE: ошибка установки пароля для ${login}: ${sanitize(e.message, pass)}`);
            // Try again after delay
            await new Promise(r => setTimeout(r, 2000));
            try {
                ldapModifyCLI(req.session, userDN, [
                    { operation: 'replace', modification: { unicodePwd: pwdBase64 } }
                ]);
                log('OK', `CREATE: пароль установлен для ${login} (со 2-й попытки)`);
            } catch(e2) {
                log('ERROR', `CREATE: пароль НЕ установлен для ${login}: ${sanitize(e2.message, pass)}`);
            }
        }
        
        // 3) Включаем пользователя
        try {
            ldapModifyCLI(req.session, userDN, [
                { operation: 'replace', modification: { userAccountControl: '512' } }
            ]);
            log('OK', `CREATE: ${login} включён`);
        } catch(e) {
            log('WARN', `CREATE: не удалось включить ${login}: ${sanitize(e.message, pass)}`);
        }

        // 4) VPN группа
        if (d.addVpn) {
            try {
                ldapModifyCLI(req.session, VPN_GROUP, [
                    { operation: 'add', modification: { member: userDN } }
                ]);
                log('OK', `CREATE: ${login} добавлен в VPN группу`);
            } catch (e) {
                log('WARN', `CREATE: VPN — ${e.message}`);
            }
        }

        // 4.5) Additional Groups
        if (d.groups && Array.isArray(d.groups)) {
            for (const gdn of d.groups) {
                try {
                    ldapModifyCLI(req.session, gdn, [
                        { operation: 'add', modification: { member: userDN } }
                    ]);
                    log('OK', `CREATE: ${login} добавлен в группу ${gdn}`);
                } catch (e) {
                    log('WARN', `CREATE: ошибка добавления в группу ${gdn}: ${e.message}`);
                }
            }
        }

        // 5) Exchange mailbox
        if (d.createMail) {
            try {
                execSync(
                    `ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 Administrator@10.2.27.118 ` +
                    `'powershell "Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010; ` +
                    `Enable-Mailbox -Identity ${login} -Database ${d.exchDb || 'DB01'}"'`,
                    { env: ENV, timeout: 30000 }
                );
                log('OK', `CREATE: почтовый ящик ${login} создан`);
            } catch (e) {
                log('WARN', `CREATE: Exchange — ${e.message}`);
            }
        }

        auditLog(req.session.username, 'CREATE', login, { displayName: d.displayName, dn: userDN });
        log('OK', `CREATE COMPLETE: ${login} (${d.displayName})`);

        // Авто-ресенк (синхронно — фронтенд получит свежие данные)
        await getADData(req.session.adUser, req.session.adPass, req.session.adUrl);

        res.json({
            success: true,
            login,
            password: pass,
            email: entry.mail,
            displayName: d.displayName
        });

    } catch (e) {
        const errMsg = sanitize(e.message, req.session.adPass);
        log('ERROR', `CREATE FAILED: ${errMsg}`);
        // Translate common LDAP errors to Russian
        let userMsg = errMsg;
        if (errMsg.includes('Already exists') || errMsg.includes('ENTRY_EXISTS')) {
            userMsg = `Пользователь с логином ${login} уже существует в AD`;
        } else if (errMsg.includes('unwilling to perform') || errMsg.includes('WILL_NOT_PERFORM')) {
            userMsg = 'Пароль не соответствует требованиям сложности AD';
        } else if (errMsg.includes('No such object')) {
            userMsg = 'Указанное подразделение (OU) не найдено';
        } else if (errMsg.includes('strong auth')) {
            userMsg = 'Требуется безопасное подключение (LDAPS)';
        }
        res.status(500).json({ success: false, error: userMsg });
    }
});

// ─── SAVE USER (update) ───────────────────────────────────────────
app.post('/api/save-user', isAuth, async (req, res) => {
    req.body = deepTrim(req.body);
const { dn, data } = req.body;
    if (!dn || !data) return res.status(400).json({ error: 'DN и данные обязательны' });

    log('INFO', `UPDATE: ${dn}`);
    const changes = [];
    const attrMap = {
        displayName: data.displayName, title: t64(data.title),
        department: t64(data.department), company: t64(data.company),
        l: t64(data.l), st: data.st, mail: data.mail, info: data.info,
        telephoneNumber: data.telephoneNumber, mobile: data.mobile,
        homePhone: data.homePhone,
        extensionAttribute1: data.sn, extensionAttribute2: data.givenName,
        extensionAttribute3: data.patronymic,
        assistant: data.assistant, description: data.description,
        physicalDeliveryOfficeName: data.office
    };

    for (const [k, v] of Object.entries(attrMap)) {
        if (v !== undefined && v !== null && v !== '') {
            changes.push({ operation: 'replace', modification: { [k]: v } });
        }
    }

    if (data.manager) {
        if (/^ваканс|^vacanc/i.test(data.manager)) {
            changes.push({ operation: 'delete', modification: { manager: '' } });
        } else {
            const mgrObj = cache.users.find(u => u.displayName === data.manager || u.dn === data.manager);
            if (mgrObj?.dn) changes.push({ operation: 'replace', modification: { manager: mgrObj.dn } });
        }
    }

    if (data.enabled !== undefined) {
        changes.push({ operation: 'replace', modification: { userAccountControl: data.enabled ? '512' : '514' } });
    }

    if (changes.length === 0) {
        log('DEBUG', 'UPDATE: нет изменений для ' + dn);
        return res.json({ success: true, message: 'Нет изменений' });
    }

    try {
        if (data.newOU && data.newOU.toLowerCase() !== getParentDN(dn).toLowerCase()) {
            // Move + update через LDIF (надёжнее с Unicode, чем ldapmodrdn с hex-escape)
            const newRDN = dn.split(',')[0];
            const decodedRDN = decodeEscapedUtf8DN(newRDN);
            const decodedNewOU = decodeEscapedUtf8DN(data.newOU);
            const pwdFile = createPasswordFile(req.session);
            const ldifFile = '/tmp/ldapmove_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6) + '.ldif';
            const decodedDnForMove = decodeEscapedUtf8DN(dn);
            const moveLdif = `dn: ${decodedDnForMove}\nchangetype: modrdn\nnewrdn: ${decodedRDN}\ndeleteoldrdn: 0\nnewsuperior: ${data.newOU}\n`;
            fs.writeFileSync(ldifFile, moveLdif);
            log('INFO', `MOVE: ${dn} → ${data.newOU}`);
            try {
                execSync(`ldapmodify -x -H ${req.session.adUrl} -D "${req.session.adUser}" -y ${pwdFile} -f ${ldifFile}`, { encoding: 'utf-8', timeout: 15000, env: ENV });
            } catch(moveErr) {
                log('ERROR', `MOVE ldapmodify failed: ${sanitize(moveErr.message, req.session.adPass)}`);
                try { fs.unlinkSync(ldifFile); } catch(e) {}
                try { fs.unlinkSync(pwdFile); } catch(e) {}
                throw moveErr;
            }
            try { fs.unlinkSync(ldifFile); } catch(e) {}
            try { fs.unlinkSync(pwdFile); } catch(e) {}
            const newDN = `${newRDN},${data.newOU}`;
            ldapModifyCLI(req.session, newDN, changes);
            auditLog(req.session.username, 'MOVE+UPDATE', dn, { newOU: data.newOU, data });
            log('OK', `MOVE+UPDATE: ${dn} → ${newDN}`);
        } else {
            ldapModifyCLI(req.session, dn, changes);
            auditLog(req.session.username, 'UPDATE', dn, data);
            log('OK', `UPDATE: ${dn} (${changes.length} изменений)`);
        }

        await getADData(req.session.adUser, req.session.adPass, req.session.adUrl);
        res.json({ success: true });

    } catch (e) {
        log('ERROR', `UPDATE FAILED: ${sanitize(e.message, req.session.adPass)}`);
        res.status(500).json({ error: `Ошибка обновления: ${sanitize(e.message, req.session.adPass)}` });
    }
});

// ─── BATCH TOGGLE (enable/disable) ────────────────────────────────
app.post('/api/batch-toggle', isAuth, async (req, res) => {
    const { dns, enabled } = req.body;
    if (!dns?.length) return res.status(400).json({ error: 'Не указаны DN пользователей' });

    const action = enabled ? 'ENABLE' : 'DISABLE';
    log('INFO', `BATCH ${action}: ${dns.length} пользователей`);

    let success = 0, failed = 0;
    const errors = [];

    for (const dn of dns) {
        try {
            ldapModifyCLI(req.session, dn, [
                { operation: 'replace', modification: { userAccountControl: enabled ? '512' : '514' } }
            ]);
            auditLog(req.session.username, action, dn, {});
            success++;
        } catch (e) {
            failed++;
            errors.push({ dn, error: sanitize(e.message, req.session.adPass) });
        }
    }

    log('OK', `BATCH ${action}: success=${success}, failed=${failed}`);
    if (success > 0) {
        await getADData(req.session.adUser, req.session.adPass, req.session.adUrl);
    }

    res.json({
        success: success,
        failed,
        total: dns.length,
        errors: errors.slice(0, 5) // первые 5 ошибок
    });
});

// ─── TOGGLE SINGLE USER ───────────────────────────────────────────
app.post('/api/toggle-user', isAuth, async (req, res) => {
    let { dn, enable, sam } = req.body;
    if (!dn) return res.status(400).json({ error: 'DN обязателен' });

    const action = enable ? 'включение' : 'отключение';
    log('INFO', `TOGGLE: ${action} ${dn}`);

    try {
        try {
            ldapModifyCLI(req.session, dn, [
                { operation: 'replace', modification: { userAccountControl: enable ? '512' : '514' } }
            ]);
        } catch (e) {
            if (e.message.includes('No such object')) {
                const searchVal = sam || dn.split(',')[0].replace('CN=', '');
                log('WARN', `DN stale for ${searchVal}, searching...`);
                const filter = sam ? `(sAMAccountName=${sam})` : `(displayName=${searchVal})`;
                const fresh = await ldapSearchAsync(req.session.adUrl, req.session.adUser, req.session.adPass, BASE_DN, filter, ['dn']);
                if (fresh && fresh[0]) {
                    ldapModifyCLI(req.session, fresh[0].dn, [{ operation: 'replace', modification: { userAccountControl: enable ? '512' : '514' } }]);
                    dn = fresh[0].dn;
                } else throw e;
            } else throw e;
        }
        auditLog(req.session.username, enable ? 'ENABLE' : 'DISABLE', dn, {});
        log('OK', `TOGGLE: ${dn} → ${enable ? 'включён' : 'отключён'}`);
        await getADData(req.session.adUser, req.session.adPass, req.session.adUrl);
        res.json({ success: true, enabled: enable });
    } catch (e) {
        log('ERROR', `TOGGLE FAILED: ${sanitize(e.message, req.session.adPass)}`);
        res.status(500).json({ error: `Ошибка ${action}: ${sanitize(e.message, req.session.adPass)}` });
    }
});

// ─── VPN ADD ──────────────────────────────────────────────────────

app.post('/api/vpn-remove', isAuth, async (req, res) => {
    const { dn } = req.body;
    if (!dn) return res.status(400).json({ error: 'DN обязателен' });
    log('INFO', `VPN REMOVE: ${dn}`);
    try {
        ldapModifyCLI(req.session, VPN_GROUP, [{ operation: 'delete', modification: { member: dn } }]);
        auditLog(req.session.username, 'VPN_REMOVE', dn, {});
        res.json({ success: true });
    } catch (e) {
        if (e.message.includes('No such attribute') || e.message.includes('16')) {
            log('OK', `VPN: ${dn} не в группе (игнорируем ошибку)`);
            return res.json({ success: true, message: 'Уже удален' });
        }
        log('ERROR', `VPN REMOVE FAILED: ${sanitize(e.message, req.session.adPass)}`);
        res.status(500).json({ error: `Ошибка удаления VPN: ${sanitize(e.message, req.session.adPass)}` });
    }
});

app.post('/api/vpn-add', isAuth, async (req, res) => {
    const { dn } = req.body;
    if (!dn) return res.status(400).json({ error: 'DN обязателен' });
    log('INFO', `VPN: добавление ${dn}`);
    try {
        ldapModifyCLI(req.session, VPN_GROUP, [{ operation: 'add', modification: { member: dn } }]);
        auditLog(req.session.username, 'VPN_ADD', dn, {});
        log('OK', `VPN: ${dn} добавлен`);
        res.json({ success: true });
    } catch (e) {
        if (e.message.includes('Type or value exists') || e.message.includes('68')) {
            log('OK', `VPN: ${dn} уже в группе (игнорируем ошибку)`);
            return res.json({ success: true, message: 'Уже в группе' });
        }
        log('ERROR', `VPN FAILED: ${sanitize(e.message, req.session.adPass)}`);
        res.status(500).json({ error: `Ошибка VPN: ${sanitize(e.message, req.session.adPass)}` }); log("ERROR", "VPN DETAIL", {err: e.message});
    }
});

// ─── CSV COMPARE ──────────────────────────────────────────────────
app.post('/api/compare-csv', isAuth, (req, res) => {
    log('INFO', 'CSV COMPARE: начало обработки');

    try {
        const csvBuf = req.body.isBase64 ? Buffer.from(req.body.csvData, 'base64') : req.body.csvData;
        const txt = iconv.decode(csvBuf, 'win1251');
        const raw = parse(txt, {
            columns: true, delimiter: ';', skip_empty_lines: true,
            relax_column_count: true, relax_quotes: true
        });

        log('DEBUG', `CSV COMPARE: распознано ${raw.length} строк`);

        const results = [];
        for (const r of raw) {
            const g = (k) => { let v = (r[k] || '').trim(); return (v === '0') ? '' : v; };
            let sn = g('Фамилия'), gn = g('Имя'), pn = g('Отчество'), fio = g('ФИО');
            // If sn/gn/pn empty, extract from displayName
            if (!sn && fio) {
                const parts = fio.trim().split(/\s+/);
                sn = parts[0] || '';
                gn = parts[1] || '';
                pn = parts[2] || '';
            }
            let login = g('Логин'); if (login === '0') login = '';

            // Генерация логина если нет
            if (!login && sn) {
                login = tr(sn);
                if (gn) login += '.' + tr(gn)[0];
                if (pn) login += tr(pn)[0];
                login = login.toLowerCase().replace(/[^a-z0-9.]/g, '');
            }

            // Авто-поиск OU
            const city = g('Город'), comp = g('Компания'), reg = g('Регион'), dept = g('Отдел');
            let siteOU = g('siteOU');
            if (!siteOU) {
                siteOU = findSiteOU(city, comp, reg, dept);
                if (siteOU) {
                    log('DEBUG', `CSV: авто-OU для ${fio}: ${siteOU.substring(0, 60)}...`);
                }
            }

            const trSn = tr(sn).replace(/^./, c => c.toUpperCase());
            const trGn = tr(gn).replace(/^./, c => c.toUpperCase());
            let cnLatin = `${trSn} ${trGn}`.trim();
            // Clone check: ищем CN в кэше с учётом decoded DN (escape-последовательности)
            const cnUpper = cnLatin.toUpperCase();
            const cnExists = cache.users.some(u => {
                if (!u.dn) return false;
                const decoded = decodeEscapedUtf8DN(u.dn).toUpperCase();
                return decoded.startsWith(`CN=${cnUpper},`);
            });
            if (cnExists) {
                // y→i→e→a: применяем ПЕРВОЕ подходящее правило
                let alt = cnLatin;
                if (/y/i.test(alt)) alt = alt.replace(/y(?!.*y)/i, 'i');
                else if (/i/i.test(alt)) alt = alt.replace(/i(?!.*i)/i, 'e');
                else if (/e/i.test(alt)) alt = alt.replace(/e(?!.*e)/i, 'a');
                else alt = alt + '2';
                cnLatin = alt;
                log('WARN', `CN CLONE: ${trSn} ${trGn} занят → ${cnLatin}`);
            }

            const hrEvent = g('Кадровое событие');

            const inc = {
                displayName: fio, sam: login, mail: g('Email'),
                cn: cnLatin, sn: sn, givenName: gn, patronymic: pn,
                title: t64(g('Должность')), department: abbrev(dept), company: abbrev(comp),
                st: reg, l: abbrev(city), info: g('Дата_Рождения'),
                telephoneNumber: g('Рабочий_Тел'), mobile: g('Мобильный'),
                homePhone: g('Телефон'),
                assistant: g('Привязки'),
                enabled: (g('Активность') !== 'Нет' && g('Активность') !== '0'),
                description: g('Описание'), office: abbrev(g('Адрес')),
                manager: g('Менеджер'), siteOU,
                hrEvent: hrEvent || ''
            };

            // Поиск существующего пользователя (УЛУЧШЕНО: Клон-контроль)
            let ex = null;
            
            // 1) По логину (самое надёжное)
            if (inc.sam) {
                ex = cache.users.find(u => u.sAMAccountName === inc.sam);
            }
            
            // 2) По Email
            if (!ex && inc.mail) {
                ex = cache.users.find(u => u.mail === inc.mail);
            }
            
            // 3) По ФИО + Дата рождения (Клон-контроль)
            if (!ex && inc.displayName) {
                const sameName = cache.users.filter(u => u.displayName === inc.displayName);
                if (sameName.length > 0) {
                    if (inc.info) {
                        // Если есть дата рождения, ищем точное совпадение
                        ex = sameName.find(u => (u.info || '').replace(/[.\/]/g, '') === inc.info.replace(/[.\/]/g, ''));
                    } else if (sameName.length === 1) {
                        // Если дата рождения не указана, но человек один — считаем его
                        ex = sameName[0];
                    }
                }
            }

            if (!ex) {
                results.push({ type: 'new', incoming: inc });
                continue;
            }

            // Сравнение полей
            const diffs = {};
            const attrs = {
                title: 'title', department: 'department', company: 'company',
                l: 'l', st: 'st', info: 'info', mail: 'mail',
                telephoneNumber: 'telephoneNumber', mobile: 'mobile',
                homePhone: 'homePhone',
                sn: 'extensionAttribute1', givenName: 'extensionAttribute2',
                patronymic: 'extensionAttribute3',
                assistant: 'assistant', description: 'description',
                office: 'physicalDeliveryOfficeName', manager: 'manager'
            };

            // Normalize: strip all double-quotes for comparison (AD escaping differs from CSV)
            const norm = (v) => String(v || '').replace(/"/g, '').trim();

            for (const [key, attr] of Object.entries(attrs)) {
                let incVal = inc[key] || '';
                let exVal = ex[attr] || '';
                let exDisplay = exVal; // для показа в UI
                let incDisplay = incVal;
                
                // Резолв DN → ФИО для менеджера (old value)
                if (key === 'manager' && exVal?.includes('=')) {
                    let m = cache.users.find(u => u.dn === exVal);
                    if (!m) m = cache.users.find(u => u.dn && exVal.includes(u.dn));
                    if (!m) {
                        const cnMatch = exVal.match(/CN=([^,]+)/);
                        if (cnMatch) { exDisplay = cnMatch[1]; exVal = cnMatch[1]; }
                    } else {
                        const cn = (m.dn || '').split(',')[0].replace(/^CN=/i, '');
                        exDisplay = `${m.displayName || exVal} (${cn})`;
                        exVal = m.displayName || exVal;
                    }
                }
                // Резолв DN → ФИО для менеджера из CSV (new value)
                if (key === 'manager' && incVal?.includes('=')) {
                    let m = cache.users.find(u => u.dn === incVal);
                    if (!m) m = cache.users.find(u => u.dn && incVal.includes(u.dn));
                    if (m) {
                        const cn = (m.dn || '').split(',')[0].replace(/^CN=/i, '');
                        incDisplay = `${m.displayName || incVal} (${cn})`;
                        incVal = m.displayName || incVal;
                    }
                }
                // Вакансия vs пустой manager — не считать изменением
                if (key === 'manager' && /^ваканс|^vacanc/i.test(incVal) && !exVal) {
                    continue;
                }
                if (incVal && norm(incVal) !== norm(exVal)) {
                    diffs[key] = { old: exDisplay, new: incDisplay };
                }
            }

            // Проверка enabled
            const exActive = !(parseInt(ex.userAccountControl) & 2);
            if (inc.enabled !== undefined && inc.enabled !== exActive) {
                diffs['enabled'] = { old: exActive, new: inc.enabled };
            }

            if (Object.keys(diffs).length > 0) {
                results.push({ type: 'diff', incoming: inc, existing: ex, diffs });
            } else {
                results.push({ type: 'same', incoming: inc, existing: ex });
            }
        }

        // Поиск дубликатов в CSV (одинаковый логин/ФИО с разными данными)
        const dupMap = {};
        for (const r of results) {
            const key = r.incoming?.sam || r.incoming?.displayName || '';
            if (key) dupMap[key] = (dupMap[key] || 0) + 1;
        }
        for (const r of results) {
            const key = r.incoming?.sam || r.incoming?.displayName || '';
            if (dupMap[key] > 1) r.duplicate = true;
        }

        const stats = {
            total: results.length,
            new: results.filter(r => r.type === 'new').length,
            diff: results.filter(r => r.type === 'diff').length,
            same: results.filter(r => r.type === 'same').length,
            duplicates: Object.values(dupMap).filter(v => v > 1).length
        };

        log('OK', `CSV COMPARE: total=${stats.total}, new=${stats.new}, diff=${stats.diff}, same=${stats.same}`);
        res.json({ success: true, results, stats });

    } catch (e) {
        log('ERROR', `CSV COMPARE: ${e.message}`);
        res.status(500).json({ success: false, error: `Ошибка разбора CSV: ${e.message}` });
    }
});

// ─── APPLY BATCH (применить импорт) ───────────────────────────────
app.post('/api/apply-batch', isAuth, async (req, res) => {
    req.body = deepTrim(req.body);
const { actions } = req.body;
    if (!actions?.length) {
        return res.status(400).json({ error: 'Нет действий для применения' });
    }

    log('INFO', `APPLY BATCH: ${actions.length} действий`);

    let success = 0, failed = 0;
    const errors = [];

    for (const action of actions) {
        try {
            if (action.type === 'update' && action.dn) {
                const d = action.data || {};
                const changes = [];
                const attrMap = {
                    displayName: d.displayName, title: t64(d.title),
                    department: t64(d.department), company: t64(d.company),
                    l: t64(d.l), st: d.st, mail: d.mail, info: d.info,
                    telephoneNumber: d.telephoneNumber, mobile: d.mobile,
                    homePhone: d.homePhone,
                    extensionAttribute1: d.sn, extensionAttribute2: d.givenName,
                    extensionAttribute3: d.patronymic,
                    assistant: d.assistant, description: d.description,
                    physicalDeliveryOfficeName: d.office
                };

                for (const [k, v] of Object.entries(attrMap)) {
                    if (v) changes.push({ operation: 'replace', modification: { [k]: v } });
                }

                // ─── Кадровые события ───────────────────────────────────
                if (d.hrEvent === 'Увольнение') {
                    changes.push({ operation: 'replace', modification: { userAccountControl: '514' } });
                    // Переподчинить подчинённых вышестоящему
                    const selfUser = cache.users.find(u => u.dn === action.dn);
                    const skipMgrDN = selfUser?.manager || '';
                    const subs = cache.users.filter(u => {
                        const mgr = (u.manager || '').toLowerCase();
                        const selfDN = (action.dn || '').toLowerCase();
                        return mgr === selfDN || mgr.includes(selfDN.substring(0, Math.min(60, selfDN.length)));
                    });
                    if (subs.length > 0) {
                        log('INFO', `HR TERM: переподчинение ${subs.length} подчинённых от ${d.sam || action.dn}`);
                        for (const sub of subs) {
                            try {
                                const subDn = decodeEscapedUtf8DN(sub.dn);
                                if (skipMgrDN) {
                                    ldapModifyCLI(req.session, subDn, [
                                        { operation: 'replace', modification: { manager: skipMgrDN } }
                                    ]);
                                } else {
                                    ldapModifyCLI(req.session, subDn, [
                                        { operation: 'replace', modification: { manager: '' } }
                                    ]);
                                }
                                auditLog(req.session.username, 'HR_REASSIGN', sub.dn, { from: d.sam, to: skipMgrDN || 'none' });
                            } catch (subErr) {
                                log('WARN', `HR REASSIGN FAILED for ${sub.sAMAccountName}: ${subErr.message}`);
                            }
                        }
                    }
                }
                if (d.hrEvent === 'Смена фамилии' && d.displayName) {
                    const parts = d.displayName.trim().split(/\s+/);
                    if (parts[0]) changes.push({ operation: 'replace', modification: { sn: parts[0] } });
                    if (parts[1]) changes.push({ operation: 'replace', modification: { givenName: parts[1] } });
                    changes.push({ operation: 'replace', modification: { displayName: d.displayName } });
                    if (d.sn) changes.push({ operation: 'replace', modification: { extensionAttribute1: d.sn } });
                    if (d.givenName) changes.push({ operation: 'replace', modification: { extensionAttribute2: d.givenName } });
                    if (d.patronymic) changes.push({ operation: 'replace', modification: { extensionAttribute3: d.patronymic } });
                }

                if (d.manager !== undefined) {
                    if (!d.manager || /^ваканс|^vacanc/i.test(d.manager)) {
                        changes.push({ operation: 'replace', modification: { manager: '' } });
                    } else {
                        const managerDN = await resolveManagerDN(req.session, d.manager);
                        if (managerDN) {
                            changes.push({ operation: 'replace', modification: { manager: managerDN } });
                        } else {
                            log('WARN', `MANAGER NOT FOUND: ${d.manager} for ${d.sam || action.dn || '?'}`);
                        }
                    }
                }

                if (d.enabled !== undefined) {
                    changes.push({
                        operation: 'replace',
                        modification: { userAccountControl: d.enabled ? '512' : '514' }
                    });
                }

                if (changes.length) {
                    // Resolve fresh DN by sAMAccountName (PowerShell approach — поиск по логину, а не по DN)
                    const cachedUser = cache.users.find(u => u.dn === action.dn);
                    const login = d.sam || (cachedUser && cachedUser.sAMAccountName);
                    let realDn = action.dn;
                    let triedFresh = false;
                    
                    if (login) {
                        try {
                            const safeLogin = escapeLDAPFilterValue(login);
                            const freshUsers = await ldapSearchAsync(req.session.adUrl, req.session.adUser, req.session.adPass, BASE_DN, `(sAMAccountName=${safeLogin})`, ['dn']);
                            if (freshUsers && freshUsers.length > 0 && freshUsers[0].dn) {
                                realDn = freshUsers[0].dn;
                                triedFresh = true;
                                log('DEBUG', `Fresh DN by sAMAccountName ${login}: ${realDn.substring(0, 80)}`);
                            }
                        } catch (srchErr) {
                            log('WARN', `ldapSearchAsync failed for ${login}: ${srchErr.message}`);
                        }
                    }
                    
                    // Decode LDAP escape sequences to proper UTF-8
                    const decodedDn = decodeEscapedUtf8DN(realDn);
                    
                    // Try ldapjs modify with decoded DN
                    try {
                        await ldapModifyJS(req.session, decodedDn, changes);
                        auditLog(req.session.username, 'BATCH_UPDATE', decodedDn, d);
                    } catch (e1) {
                        log('WARN', `ldapModifyJS failed for ${login || decodedDn?.substring(0,50)}: ${e1.message}`);
                        // Fallback to CLI (стабильнее с AD DN через LDIF)
                        try {
                            ldapModifyCLI(req.session, decodedDn, changes);
                            auditLog(req.session.username, 'BATCH_UPDATE_CLI_FALLBACK', decodedDn, d);
                            log('OK', `BATCH UPDATE via CLI fallback: ${login || decodedDn}`);
                        } catch (e2) {
                            log('ERROR', `CLI fallback failed for ${login || decodedDn}: ${sanitize(e2.message, req.session.adPass)}`);
                            throw e2;
                        }
                    }
                }
                success++;
            } else if (action.type === 'create' && action.data) {
                const d = action.data;
                if (!d.siteOU) {
                    failed++;
                    errors.push({ name: d.displayName || '?', error: 'Не указано подразделение (OU)' });
                    continue;
                }

                const parts = (d.displayName || '').trim().split(/\s+/);
                const sn = (d.sn || parts[0] || '').trim();
                const gn = (d.givenName || parts[1] || '').trim();
                const pn = (d.patronymic || parts[2] || '').trim();

                const trSn = tr(sn).replace(/^./, c => c.toUpperCase());
                const trGn = tr(gn).replace(/^./, c => c.toUpperCase());
                let login = (d.sam || (tr(sn) + '.' + (tr(gn)[0] || '')).toLowerCase().replace(/[^a-z0-9.]/g, '')).trim();

                // Проверка уникальности
                if (cache.users.find(u => u.sAMAccountName === login)) {
                    failed++;
                    errors.push({ name: d.displayName, error: `Логин ${login} уже занят` });
                    continue;
                }

                const siteOU = d.siteOU.toUpperCase().startsWith('OU=USERS,') ?
                    d.siteOU : `OU=Users,${d.siteOU}`;
                let cnLatin = `${trSn} ${trGn}`.trim();
                // Уникальность CN — clone check с decoded DN
                const cnUpper = cnLatin.toUpperCase();
                const cnExists = cache.users.some(u => {
                    if (!u.dn) return false;
                    const decoded = decodeEscapedUtf8DN(u.dn).toUpperCase();
                    return decoded.startsWith(`CN=${cnUpper},`);
                });
                if (cnExists) {
                    let alt = cnLatin;
                    if (/y/i.test(alt)) alt = alt.replace(/y(?!.*y)/i, 'i');
                    else if (/i/i.test(alt)) alt = alt.replace(/i(?!.*i)/i, 'e');
                    else if (/e/i.test(alt)) alt = alt.replace(/e(?!.*e)/i, 'a');
                    else alt = alt + '2';
                    cnLatin = alt;
                    log('WARN', `CN CLONE: ${trSn} ${trGn} занят → ${cnLatin}`);
                }
                const userDN = `CN=${escapeDN(cnLatin)},${siteOU}`;
                const pass = `Agro${Math.random().toString(36).substring(2, 10)}!`;

                const entry = {
                    cn: cnLatin, displayName: d.displayName,
                    sn: trSn, givenName: trGn,
                    sAMAccountName: login,
                    userPrincipalName: login + '@ahprostory.ru',
                    objectClass: ['top', 'person', 'organizationalPerson', 'user'],
                    title: t64(d.title), department: t64(d.department), company: t64(d.company),
                    l: t64(d.l), st: d.st,
                    mail: d.mail || (login + '@ahprostory.ru'),
                    extensionAttribute1: sn, extensionAttribute2: gn,
                    extensionAttribute3: pn
                };

                ldapAddCLI(req.session, userDN, entry);
                
                // Small delay for replication
                await new Promise(r => setTimeout(r, 800));
                const pwdBase64 = Buffer.from(`"${pass}"`, 'utf16le').toString('base64');
                ldapModifyCLI(req.session, userDN, [
                    { operation: 'replace', modification: { unicodePwd: pwdBase64 } }
                ]);
                ldapModifyCLI(req.session, userDN, [
                    { operation: 'replace', modification: { userAccountControl: '512' } }
                ]);

                auditLog(req.session.username, 'BATCH_CREATE', login, { displayName: d.displayName });
                success++;
            }
        } catch (e) {
            failed++;
            const errMsg = sanitize(e.message, req.session.adPass);
            errors.push({
                name: action.data?.displayName || action.dn || '?',
                error: errMsg.substring(0, 200)
            });
            log('WARN', `APPLY BATCH ERROR: ${errMsg}`);
        }
    }

    log('OK', `APPLY BATCH COMPLETE: success=${success}, failed=${failed}`);

    if (success > 0) {
        await getADData(req.session.adUser, req.session.adPass, req.session.adUrl);
    }

    res.json({
        success,
        failed,
        total: actions.length,
        errors: errors.slice(0, 20)
    });
});


// ─── GROUP MANAGEMENT ─────────────────────────────────────────────
app.post('/api/group-add', isAuth, async (req, res) => {
    const { userDn, groupDn } = req.body;
    if (!userDn || !groupDn) return res.status(400).json({ error: 'User DN and Group DN required' });
    log('INFO', `GROUP ADD: User=${userDn} to Group=${groupDn}`);
    try {
        ldapModifyCLI(req.session, groupDn, [{ operation: 'add', modification: { member: userDn } }]);
        auditLog(req.session.username, 'GROUP_ADD', userDn, { group: groupDn });
        res.json({ success: true });
    } catch (e) {
        if (e.message.includes('Type or value exists') || e.message.includes('68')) {
            return res.json({ success: true, message: 'Already a member' });
        }
        log('ERROR', `GROUP ADD FAILED: ${sanitize(e.message, req.session.adPass)}`);
        res.status(500).json({ error: `Ошибка добавления в группу: ${sanitize(e.message, req.session.adPass)}` });
    }
});

app.post('/api/group-remove', isAuth, async (req, res) => {
    const { userDn, groupDn } = req.body;
    if (!userDn || !groupDn) return res.status(400).json({ error: 'User DN and Group DN required' });
    log('INFO', `GROUP REMOVE: User=${userDn} from Group=${groupDn}`);
    try {
        ldapModifyCLI(req.session, groupDn, [{ operation: 'delete', modification: { member: userDn } }]);
        auditLog(req.session.username, 'GROUP_REMOVE', userDn, { group: groupDn });
        res.json({ success: true });
    } catch (e) {
        if (e.message.includes('No such attribute') || e.message.includes('16')) {
            return res.json({ success: true, message: 'Not a member' });
        }
        log('ERROR', `GROUP REMOVE FAILED: ${sanitize(e.message, req.session.adPass)}`);
        res.status(500).json({ error: `Ошибка удаления из группы: ${sanitize(e.message, req.session.adPass)}` });
    }
});

// ─── EXPORT CSV ───────────────────────────────────────────────────
app.get('/api/export-csv', isAuth, (req, res) => {
    let users = cache.users.filter(u => !isTechnicalAccount(u));
    const getMgrName = (dn) => {
        if (!dn) return '';
        // Case-insensitive + decoded escape sequences match
        const decoded = decodeEscapedUtf8DN(dn).toLowerCase();
        const m = cache.users.find(u => decodeEscapedUtf8DN(u.dn || '').toLowerCase() === decoded);
        return m ? m.displayName : dn;
    };

    // Фильтры
    const filter = req.query.filter || 'all';
    if (filter === 'with_attrs') {
        users = users.filter(u => u.manager && u.department);
    } else if (filter === 'no_attrs') {
        users = users.filter(u => !u.manager || !u.department);
    }
    if (req.query.active === 'true') {
        users = users.filter(u => !(parseInt(u.userAccountControl) & 2));
    }

    const label = filter === 'with_attrs' ? 'with_manager_dept' : filter === 'no_attrs' ? 'no_manager_dept' : 'all';

    let csv = 'Кадровое событие;Активность;Фамилия;Имя;Отчество;ФИО;Логин;Email;Должность;Отдел;Компания;Регион;Город;Дата_Рождения;Телефон;Рабочий_Тел;Мобильный;Привязки;Описание;Адрес;Менеджер\n';

    for (const u of users) {
        const parts = (u.displayName || '').trim().split(/\s+/);
        const sn = u.extensionAttribute1 || u.sn || parts[0] || '';
        const gn = u.extensionAttribute2 || u.givenName || parts[1] || '';
        const pn = u.extensionAttribute3 || parts[2] || '';
        const mail = u.mail || (u.sAMAccountName ? u.sAMAccountName + '@ahprostory.ru' : '');
        csv += [
            '',
            (parseInt(u.userAccountControl) & 2) ? 'Нет' : 'Да',
            sn, gn, pn,
            u.displayName || '', u.sAMAccountName || '', mail,
            u.title || '', u.department || '', u.company || '',
            u.st || '', u.l || '', u.info || '',
            u.homePhone || '', u.telephoneNumber || '', u.mobile || '',
            u.assistant || '', u.description || '',
            u.physicalDeliveryOfficeName || '',
            getMgrName(u.manager)
        ].join(';') + '\n';
    }

    log('INFO', `EXPORT CSV (${filter}): ${users.length} пользователей`);
    res.setHeader('Content-Type', 'text/csv; charset=windows-1251');
    res.setHeader('Content-Disposition', `attachment; filename=ad_export_${label}.csv`);
    res.send(iconv.encode(csv, 'win1251'));
});

// ─── AUDIT ────────────────────────────────────────────────────────

app.get('/api/audit/operators', isAuth, (req, res) => {
    try {
        const rows = audit.prepare('SELECT DISTINCT operator FROM audit ORDER BY operator').all();
        res.json(rows.map(r => r.operator));
    } catch(e) { res.status(500).json({ error: e.message }); }
});

app.get('/api/audit/download', isAuth, (req, res) => {
    const operator = req.query.operator;
    try {
        let rows;
        if (operator) {
            rows = audit.prepare('SELECT ts, action, target, details FROM audit WHERE operator = ? ORDER BY id DESC').all(operator);
        } else {
            rows = audit.prepare('SELECT ts, operator, action, target, details FROM audit ORDER BY id DESC LIMIT 5000').all();
        }
        
        let txt = operator ? `AUDIT LOG FOR: ${operator}\n\n` : `FULL AUDIT LOG (Last 5000)\n\n`;
        txt += "Timestamp | Action | Target | Details\n" + "-".repeat(80) + "\n";
        
        for (const r of rows) {
            const line = `${r.ts} | ${operator ? '' : r.operator + ' | '}${r.action} | ${r.target} | ${r.details}\n`;
            txt += line;
        }
        
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Content-Disposition', `attachment; filename=audit_${operator || 'full'}.txt`);
        res.send(txt);
    } catch(e) { res.status(500).send(e.message); }
});
app.get('/api/audit', isAuth, (req, res) => {
    try {
        const rows = audit ?
            audit.prepare('SELECT * FROM audit ORDER BY id DESC LIMIT 200').all() :
            [];
        res.json(rows);
    } catch (e) {
        res.json([]);
    }
});


function isTechnicalAccount(u) {
    const disp = (u.displayName || '').toLowerCase();
    const desc = (u.description || '').toLowerCase();
    const sam = (u.sAMAccountName || '').toLowerCase();
    
    // Keywords for technical/service accounts
    const keywords = [
        'admin', 'техническ', 'учетка', 'запись', 'service', 'backup', 'bkp', 
        'monitoring', 'sql', 'veeam', 'zabbix', '1c_', '1с_', 'ldap', 'help', 
        'forticon', 'meec', 'fs_work', 'dev', 'ops', 'prod', 'test',
        'healthmailbox', 'systemmailbox', 'discovery', 'microsoft exchange',
        'smtp_', 'sm_', 'smtp{', 'fax_', 'e4e encryption',
        'ad_support', 'support', 'pbx', 'usr1c', 'usrbcp', 'room', 'equipment',
    ];
    
    // Check SAM account name
    if (keywords.some(k => sam.includes(k))) return true;
    if (sam.startsWith('_') || sam.startsWith('$')) return true;
    
    // Check Display Name
    if (keywords.some(k => disp.includes(k))) return true;
    if (disp.includes('(admin') || disp.includes('adminws')) return true;
    
    // Check Description
    if (keywords.some(k => desc.includes(k))) return true;
    
    return false;
}


app.get('/api/debug-find/:sam', isAuth, async (req, res) => {
    try {
        const filter = `(sAMAccountName=${req.params.sam})`;
        const r = await ldapSearchAsync(req.session.adUrl, req.session.adUser, req.session.adPass, BASE_DN, filter, ['*']);
        res.json(r);
    } catch(e) { res.status(500).send(e.message); }
});
// ─── REPORTS ──────────────────────────────────────────────────────
app.get('/api/report/duplicates', isAuth, (req, res) => {
    const hideTech = req.query.hideTech === "true";
    const nameMap = {};
    for (const u of cache.users) {
        if (hideTech && isTechnicalAccount(u)) continue;
        const name = (u.displayName || '').toLowerCase().trim();
        if (!name) continue;
        if (!nameMap[name]) nameMap[name] = [];
        nameMap[name].push({ sam: u.sAMAccountName || '?', dn: u.dn });
    }
    const dups = Object.entries(nameMap)
        .filter(([_, users]) => users.length > 1)
        .map(([name, users]) => ({ name, users }));
    res.json(dups);
});

app.get('/api/report/empty-attrs', isAuth, (req, res) => {
    const hideTech = req.query.hideTech === 'true';
    // Critical attributes for audit
    const attrs = {
        'sn': 'Фамилия',
        'givenName': 'Имя',
        'extensionAttribute3': 'Отчество',
        'title': 'Должность',
        'department': 'Отдел',
        'company': 'Компания',
        'mail': 'Email',
        'l': 'Город',
        'st': 'Регион',
        'telephoneNumber': 'Раб.тел',
        'mobile': 'Моб.тел',
        'manager': 'Руководитель'
    };
    const empty = [];
    for (const u of cache.users) {
        if (hideTech && isTechnicalAccount(u)) continue;
        const missing = [];
        for (const [key, label] of Object.entries(attrs)) {
            if (!u[key] || u[key] === '' || u[key] === '0') {
                missing.push(label);
            }
        }
        if (missing.length > 0) {
            empty.push({
                name: u.displayName || '?',
                sam: u.sAMAccountName || '?',
                empty: missing
            });
        }
    }
    res.json(empty);
});

// ─── XLSX VIEW ────────────────────────────────────────────────────
// Store last uploaded XLSX path in session
app.post('/api/xlsx-upload', isAuth, (req, res) => {
    try {
        const buf = req.body.isBase64 ? Buffer.from(req.body.data, 'base64') : req.body.data;
        const xlsxPath = '/tmp/uploaded_struct_' + (req.session.username || 'anon') + '.xlsx';
        fs.writeFileSync(xlsxPath, buf);
        req.session.xlsxPath = xlsxPath;
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.get('/api/xlsx-view', isAuth, (req, res) => {
    try {
        const xlsxPath = req.session.xlsxPath || '/home/agroadmin/test22.xlsx';
        if (!fs.existsSync(xlsxPath)) return res.status(404).json({ error: 'XLSX не найден. Загрузите файл.' });
        
        const script = `import json, sys
from openpyxl import load_workbook
wb = load_workbook('${xlsxPath}', data_only=True)
ws = wb.active

# Авто-определение колонок по заголовкам (первая строка)
headers = [str(c.value or '').strip().lower() for c in ws[1]]
col_map = {}
for i, h in enumerate(headers):
    if 'логин' in h: col_map['login'] = i
    elif 'email' in h or 'почт' in h: col_map['email'] = i
    elif 'фио' in h and 'из' not in h: col_map['fio'] = i
    elif 'компан' in h or 'юр' in h: col_map['company'] = i
    elif 'отдел' in h and ('загруз' in h or 'к_загруз' in h or 'подраздел' in h): col_map['dept_load'] = i
    elif 'отдел' in h: col_map['dept_load'] = i
    elif 'долж' in h and 'загруз' in h: col_map['title_load'] = i
    elif 'долж' in h: col_map['title_load'] = i
    elif 'руковод' in h and 'sam' in h: col_map['mgr_load'] = i
    elif 'руковод' in h or 'менеджер' in h: col_map['mgr_name'] = i
    elif 'город' in h or 'местополож' in h: col_map['city'] = i
    elif 'рожден' in h: col_map['info'] = i
    elif 'регион' in h or 'принад' in h: col_map['region'] = i
    elif 'актив' in h: col_map['active'] = i
    elif 'кадровое' in h: col_map['hrevent'] = i
    elif 'фамилия' in h: col_map['sn'] = i
    elif 'имя' in h: col_map['gn'] = i
    elif 'отчество' in h: col_map['pn'] = i
    elif 'телефон' in h: col_map['phone'] = i
    elif 'мобил' in h: col_map['mobile'] = i
    elif 'рабоч' in h: col_map['workphone'] = i

from datetime import datetime
def fmt_val(v):
    if v is None: return ''
    if isinstance(v, datetime):
        return v.strftime('%d.%m.%Y')
    return str(v).strip()

rows = []
for row in ws.iter_rows(min_row=2, values_only=True):
    r = {}
    for key, idx in col_map.items():
        val = row[idx] if idx < len(row) else None
        r[key] = fmt_val(val)
    if r.get('login'):
        rows.append(r)
print(json.dumps(rows, ensure_ascii=False))
`;
        const pyFile = '/tmp/xlsx_parse_' + Date.now() + '.py';
        fs.writeFileSync(pyFile, script);
        const out = execSync(`python3 ${pyFile}`, { encoding: 'utf-8', timeout: 15000 });
        try { fs.unlinkSync(pyFile); } catch(e) {}
        const rows = JSON.parse(out);
        
        // Универсальное сопоставление XLSX ↔ AD по всем полям
        const FIELD_MAP = [
            ['fio', 'displayName', 'ФИО'],
            ['email', 'mail', 'Email'],
            ['dept_load', 'department', 'Отдел'],
            ['title_load', 'title', 'Должность'],
            ['company', 'company', 'Компания'],
            ['city', 'l', 'Город'],
            ['region', 'st', 'Регион'],
            ['info', 'info', 'Дата рождения'],
        ];
        // Дополнительные сравнения: смотрим расхождения AD-атрибутов

        const enriched = rows.map(r => {
            const adUser = cache.users.find(u => u.sAMAccountName === r.login);
            const diffs = {};
            if (!adUser) return { 
                login: r.login, fio: r.fio, hasDiff: true, isNew: true, diffs: {}, adFio: '',
                hrevent: r.hrevent || '',
                _fields: {
                    title: r.title_load || '', department: r.dept_load || '', company: r.company || '',
                    region: r.region || '', city: r.city || '', email: r.email || '',
                    phone: r.phone || '', mobile: r.mobile || '', info: r.info || '',
                    desc: r.desc || '', addr: r.addr || '',
                    manager: r.mgr_name || r.mgr_load || '',
                    sn: r.sn || '', gn: r.gn || '', pn: r.pn || ''
                }
            };
            
            for (const [xlsxKey, adAttr, label] of FIELD_MAP) {
                let xVal = (r[xlsxKey] || '').trim();
                let adVal = (adUser[adAttr] || '').trim();
                // Нормализация: title/department через smartTitle/abbrev
                if (adAttr === 'title' || adAttr === 'department') {
                    xVal = t64(xVal);
                    adVal = t64(adVal);
                }
                if (xVal && xVal !== adVal) {
                    diffs[adAttr] = { label, ad: adVal, xlsx: xVal };
                }
            }

            // CN — информативно, не влияет на счётчик
            const adCN = decodeEscapedUtf8DN(adUser.dn || '').split(',')[0].replace(/^CN=/i, '').trim();
            if (adCN) diffs['_cn'] = { label: 'CN', ad: adCN, xlsx: '(из AD)' };
            
            // Manager — сравнение по SAM (приводим ФИО к SAM через кэш)
            const mgrSam = r.mgr_load || r.mgr_struct_sam || '';
            const mgrDisplay = r.mgr_name || '';
            if (mgrSam || mgrDisplay) {
                const adMgrSam = (() => {
                    if (!adUser?.manager) return '';
                    const m = cache.users.find(u => u.dn === adUser.manager);
                    return m?.sAMAccountName || '';
                })();
                // Приводим XLSX-значение к SAM (точное + нечёткое)
                let xlsxMgrSam = mgrSam;
                if (!xlsxMgrSam && mgrDisplay) {
                    let m = cache.users.find(u => u.displayName === mgrDisplay);
                    if (!m) {
                        // Нечёткий поиск: Фамилия + первые буквы Имени
                        const parts = mgrDisplay.trim().split(/\s+/);
                        if (parts.length >= 2) {
                            m = cache.users.find(u => {
                                const dp = (u.displayName || '').trim().split(/\s+/);
                                return dp[0] === parts[0] && dp.length >= 2 && dp[1][0] === parts[1][0];
                            });
                        }
                    }
                    xlsxMgrSam = m?.sAMAccountName || mgrDisplay;
                }
                if (adMgrSam && xlsxMgrSam && xlsxMgrSam !== adMgrSam) {
                    diffs['manager'] = { label: 'Руководитель', ad: adMgrSam, xlsx: xlsxMgrSam };
                }
            }
            
            return {
                login: r.login, fio: r.fio, adFio: adUser.displayName || '',
                hrevent: r.hrevent || '', diffs,
                hasDiff: Object.keys(diffs).filter(k => !k.startsWith('_')).length > 0
            };
        });
        
        res.json({ rows: enriched, total: enriched.length });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.post('/api/xlsx-apply', isAuth, async (req, res) => {
    const { items } = req.body;
    if (!items?.length) return res.json({ success: 0, failed: 0 });
    
    let success = 0, failed = 0;
    for (const item of items) {
        try {
            let adUser = cache.users.find(u => u.sAMAccountName === item.login);
            
            // Для «Приёма» — если пользователя нет в AD, создаём его
            const hreventNorm = (item.hrevent || '').replace(/ё/g, 'е').toLowerCase();
            if (!adUser && hreventNorm === 'прием') {
                try {
                    // ФИО может быть пустым — пробуем собрать из других полей
                    let fio = (item.fio || '').trim();
                    if (!fio) {
                        // Пробуем собрать из item (sn/gn/pn могут прийти как отдельные атрибуты)
                        fio = [item.sn, item.gn, item.pn].filter(Boolean).join(' ') || '';
                    }
                    if (!fio) {
                        log('ERROR', `XLSX HIRE CREATE: пустое ФИО для логина ${item.login} — невозможно создать`);
                        failed++; continue;
                    }
                    const parts = fio.trim().split(/\s+/);
                    const sn = parts[0] || '';
                    const gn = parts[1] || '';
                    const pn = parts[2] || '';
                    const trSn = tr(sn).replace(/^./, c => c.toUpperCase());
                    const trGn = tr(gn).replace(/^./, c => c.toUpperCase());
                    let login = item.login || (tr(sn) + '.' + (tr(gn)[0] || '')).toLowerCase().replace(/[^a-z0-9.]/g, '');
                    
                    // Проверка уникальности логина
                    if (cache.users.find(u => u.sAMAccountName === login)) {
                        log('WARN', `XLSX HIRE CREATE: логин ${login} уже занят`);
                        failed++; continue;
                    }
                    
                    // Авто-поиск OU
                    let siteOU = findSiteOU(item.city, item.company, item.region, item.dept);
                    if (!siteOU) {
                        log('WARN', `XLSX HIRE CREATE: не найден OU для ${item.fio} (город=${item.city}, регион=${item.region})`);
                        failed++; continue;
                    }
                    siteOU = siteOU.toUpperCase().startsWith('OU=USERS,') ? siteOU : `OU=Users,${siteOU}`;
                    
                    let cnLatin = `${trSn} ${trGn}`.trim();
                    const cnUpper = cnLatin.toUpperCase();
                    if (cache.users.some(u => u.dn && decodeEscapedUtf8DN(u.dn).toUpperCase().startsWith(`CN=${cnUpper},`))) {
                        if (/y/i.test(cnLatin)) cnLatin = cnLatin.replace(/y(?!.*y)/i, 'i');
                        else if (/i/i.test(cnLatin)) cnLatin = cnLatin.replace(/i(?!.*i)/i, 'e');
                        else cnLatin = cnLatin + '2';
                    }
                    const userDN = `CN=${escapeDN(cnLatin)},${siteOU}`;
                    const pass = `Agro${Math.random().toString(36).substring(2, 10)}!`;
                    
                    item.fio = fio; // обновляем на случай если был пустым
                    const entry = {
                        cn: cnLatin, displayName: fio,
                        sn: trSn, givenName: trGn,
                        sAMAccountName: login,
                        userPrincipalName: login + '@ahprostory.ru',
                        objectClass: ['top', 'person', 'organizationalPerson', 'user'],
                        title: t64(item.title), department: t64(item.dept), company: t64(item.company),
                        l: t64(item.city), st: item.region,
                        mail: item.email || (login + '@ahprostory.ru'),
                        extensionAttribute1: sn, extensionAttribute2: gn,
                        extensionAttribute3: pn
                    };
                    if (item.phone) entry.telephoneNumber = item.phone;
                    if (item.mobile) entry.mobile = item.mobile;
                    if (item.birthday) entry.info = item.birthday;
                    if (item.desc) entry.description = item.desc;
                    if (item.addr) entry.physicalDeliveryOfficeName = t64(item.addr);
                    if (item.manager && !/^ваканс|^vacanc/i.test(item.manager)) {
                        const mgrObj = cache.users.find(u => u.displayName === item.manager || u.sAMAccountName === item.manager);
                        if (mgrObj?.dn) entry.manager = mgrObj.dn;
                    }
                    
                    log('INFO', `XLSX HIRE CREATE: ${item.fio} → login=${login}, OU=${siteOU.substring(0, 60)}`);
                    ldapAddCLI(req.session, userDN, entry);
                    
                    await new Promise(r => setTimeout(r, 1500));
                    const pwdBase64 = Buffer.from(`"${pass}"`, 'utf16le').toString('base64');
                    ldapModifyCLI(req.session, userDN, [{ operation: 'replace', modification: { unicodePwd: pwdBase64 } }]);
                    ldapModifyCLI(req.session, userDN, [{ operation: 'replace', modification: { userAccountControl: '512' } }]);
                    
                    auditLog(req.session.username, 'XLSX_HIRE_CREATE', login, { displayName: item.fio, ou: siteOU });
                    log('OK', `XLSX HIRE CREATE: ${login} создан и активирован`);
                    
                    // Обновляем кэш и находим созданного пользователя
                    await getADData(req.session.adUser, req.session.adPass, req.session.adUrl);
                    adUser = cache.users.find(u => u.sAMAccountName === login);
                    if (!adUser) { success++; continue; } // создан, но не в кэше — всё равно успех
                } catch (e) {
                    log('ERROR', `XLSX HIRE CREATE failed: ${item.fio}: ${sanitize(e.message, req.session.adPass)}`);
                    failed++; continue;
                }
            }
            
            if (!adUser) { failed++; continue; }
            
            const changes = [];
            
            // Кадровые события из XLSX (hreventNorm уже определён выше)
            if (hreventNorm === 'увольнение') {
                // Битово устанавливаем флаг ACCOUNTDISABLE (2)
                const currentUAC = parseInt(adUser.userAccountControl) || 512;
                const newUAC = (currentUAC | 2).toString();
                changes.push({ operation: 'replace', modification: { userAccountControl: newUAC } });
                log('INFO', `XLSX TERM: отключение ${item.login} (UAC: ${currentUAC} → ${newUAC})`);
                // Переподчинить подчинённых
                const subs = cache.users.filter(u => {
                    const mgr = (u.manager || '').toLowerCase();
                    const selfDN = (adUser.dn || '').toLowerCase();
                    return mgr === selfDN || mgr.includes(selfDN.substring(0, Math.min(60, selfDN.length)));
                });
                if (subs.length > 0) {
                    const skipMgrDN = adUser.manager || '';
                    log('INFO', `XLSX TERM: переподчинение ${subs.length} подчинённых ${item.login} → вышестоящему (skipMgrDN: ${skipMgrDN.substring(0, 60)})`);
                    for (const sub of subs) {
                        try {
                            const subDn = decodeEscapedUtf8DN(sub.dn);
                            ldapModifyCLI(req.session, subDn, [
                                { operation: 'replace', modification: { manager: skipMgrDN || '' } }
                            ]);
                            log('INFO', `XLSX TERM reassign OK: ${sub.sAMAccountName} → ${skipMgrDN.substring(0, 40)}`);
                        } catch (subErr) {
                            log('WARN', `XLSX TERM reassign failed: ${sub.sAMAccountName}: ${subErr.message}`);
                        }
                    }
                } else {
                    log('INFO', `XLSX TERM: у ${item.login} нет подчинённых для переподчинения`);
                }
            }
            if (hreventNorm === 'прием') {
                // Активировать пользователя (снять ACCOUNTDISABLE, бит 2)
                const currentUAC = parseInt(adUser.userAccountControl) || 512;
                if (currentUAC & 2) {
                    const newUAC = (currentUAC & ~2).toString();
                    changes.push({ operation: 'replace', modification: { userAccountControl: newUAC } });
                    log('INFO', `XLSX HIRE: активация ${item.login} (UAC: ${currentUAC} → ${newUAC})`);
                } else {
                    log('INFO', `XLSX HIRE: ${item.login} уже активен (UAC: ${currentUAC})`);
                }
                
                // Если принимают на должность руководителя — переподчинить сотрудников отдела
                // Проверяем и новую должность (из XLSX), и текущую (из AD) — на случай если diff пустой
                const checkTitle = item.title || adUser.title || '';
                const isManagerTitle = /начальник|руководитель|директор|заведующ|управляющ|глава|командир/i.test(checkTitle);
                const dept = item.dept || adUser.department || '';
                if (isManagerTitle && dept) {
                    const deptNorm = t64(dept).toLowerCase();
                    const selfDN = (adUser.dn || '').toLowerCase();
                    const subs = cache.users.filter(u => {
                        const uDept = (u.department || '').toLowerCase();
                        if (uDept !== deptNorm) return false;
                        const mgr = (u.manager || '').toLowerCase();
                        if (mgr === selfDN) return false; // уже подчиняется
                        if (u.sAMAccountName === item.login) return false; // не себя
                        return true;
                    });
                    if (subs.length > 0) {
                        log('INFO', `XLSX HIRE: переподчинение ${subs.length} сотрудников отдела "${dept}" → ${item.login}`);
                        for (const sub of subs) {
                            try {
                                const subDn = decodeEscapedUtf8DN(sub.dn);
                                ldapModifyCLI(req.session, subDn, [
                                    { operation: 'replace', modification: { manager: adUser.dn } }
                                ]);
                                log('INFO', `XLSX HIRE reassign OK: ${sub.sAMAccountName} → ${item.login}`);
                            } catch (subErr) {
                                log('WARN', `XLSX HIRE reassign failed: ${sub.sAMAccountName}: ${subErr.message}`);
                            }
                        }
                    } else {
                        log('INFO', `XLSX HIRE: нет сотрудников для переподчинения в отделе "${dept}"`);
                    }
                }
            }
            if (hreventNorm === 'перевод') {
                // Обновить отдел + должность (без отключения)
                if (item.dept) changes.push({ operation: 'replace', modification: { department: t64(item.dept) } });
                if (item.title) changes.push({ operation: 'replace', modification: { title: t64(item.title) } });
                
                let mgrValue = item.manager;
                // Авто-поиск руководителя нового отдела, если не указан явно
                if (!mgrValue && item.dept) {
                    const newDeptNorm = t64(item.dept).toLowerCase();
                    const deptManagers = cache.users.filter(u => {
                        const uDept = (u.department || '').toLowerCase();
                        if (uDept !== newDeptNorm) return false;
                        const ttl = (u.title || '').toLowerCase();
                        return /начальник|руководитель|директор|заведующ|управляющ|глава|командир/i.test(ttl);
                    });
                    if (deptManagers.length > 0) {
                        // Приоритет: не стажёр, затем по логину (основной длиннее)
                        deptManagers.sort((a, b) => {
                            const aIntern = /стаж[её]р/i.test(a.title || '') ? 1 : 0;
                            const bIntern = /стаж[её]р/i.test(b.title || '') ? 1 : 0;
                            if (aIntern !== bIntern) return aIntern - bIntern;
                            return (b.sAMAccountName || '').length - (a.sAMAccountName || '').length;
                        });
                        mgrValue = deptManagers[0].sAMAccountName || deptManagers[0].displayName;
                        log('INFO', `XLSX TRANSFER: авто-руководитель для ${item.login} → отдел="${item.dept}" → ${mgrValue} (${deptManagers[0].displayName})`);
                    } else {
                        log('WARN', `XLSX TRANSFER: не найден руководитель отдела "${item.dept}" для ${item.login}`);
                    }
                }
                
                if (mgrValue) {
                    const mgrDN = await resolveManagerDN(req.session, mgrValue);
                    if (mgrDN) {
                        changes.push({ operation: 'replace', modification: { manager: mgrDN } });
                        log('INFO', `XLSX TRANSFER: менеджер для ${item.login} → ${mgrValue}`);
                    } else {
                        log('WARN', `XLSX TRANSFER: resolveManagerDN НЕ НАШЁЛ "${mgrValue}" для ${item.login}`);
                    }
                }
            }
            if (hreventNorm === 'смена фамилии' && item.fio) {
                const parts = item.fio.trim().split(/\s+/);
                if (parts[0]) changes.push({ operation: 'replace', modification: { sn: parts[0] } });
                if (parts[1]) changes.push({ operation: 'replace', modification: { givenName: parts[1] } });
                changes.push({ operation: 'replace', modification: { displayName: item.fio } });
            }
            
            const attrMap = {
                displayName: item.fio, title: item.title, department: item.dept,
                company: item.company, l: item.city, st: item.region,
                mail: item.email, telephoneNumber: item.phone,
                mobile: item.mobile, info: item.birthday,
                description: item.desc, physicalDeliveryOfficeName: item.addr
            };
            for (const [k, v] of Object.entries(attrMap)) {
                if (v) changes.push({ operation: 'replace', modification: { [k]: k === 'title' || k === 'department' ? t64(v) : v } });
            }
            if (item.manager) {
                const mgrDN = await resolveManagerDN(req.session, item.manager);
                if (mgrDN) changes.push({ operation: 'replace', modification: { manager: mgrDN } });
            }
            
            if (changes.length) {
                log('INFO', `XLSX APPLY: ${item.login} — ${changes.length} changes: ${JSON.stringify(changes).substring(0, 200)}`);
                const decodedDn = decodeEscapedUtf8DN(adUser.dn);
                try {
                    await ldapModifyJS(req.session, decodedDn, changes);
                } catch (e1) {
                    ldapModifyCLI(req.session, decodedDn, changes);
                }
                auditLog(req.session.username, 'XLSX_APPLY', item.login, { changes: changes.map(c => ({ op: c.operation, attr: Object.keys(c.modification||{})[0] })) });
            }
            success++;
        } catch (e) {
            failed++;
        }
    }
    
    if (success > 0) await getADData(req.session.adUser, req.session.adPass, req.session.adUrl);
    res.json({ success, failed });
});

// ─── FIX CYRILLIC CN → LATIN ──────────────────────────────────────
app.post('/api/fix-cn', isAuth, async (req, res) => {
    let fixed = 0, skipped = 0, failed = 0;
    const results = [];
    
    for (const u of cache.users) {
        try {
            const rawCN = (u.dn || '').split(',')[0].replace(/^CN=/i, '').trim();
            const decodedCN = decodeEscapedUtf8DN(rawCN);
            if (!/[а-яё]/i.test(decodedCN)) { skipped++; continue; }
            
            // Пропускаем технические/сервисные учётки и спец-OU
            const dnUpper = (u.dn || '').toUpperCase();
            if (/(OU=Special|OU=Tech Users|OU=Shared Mailboxes|OU=Admin Users|OU=Servers|OU=Service)/i.test(dnUpper)) { skipped++; continue; }
            if (/(_adm|_svc|_tech|_scan|svc_|adm_)/i.test(u.sAMAccountName || '')) { skipped++; continue; }
            const uac = parseInt(u.userAccountControl) || 0;
            if (uac & 0x80000) { skipped++; continue; }
            
            // Ищем ЖИВОЙ DN через LDAP (кэш может быть stale)
            const safeSam = escapeLDAPFilterValue(u.sAMAccountName);
            let liveDN = u.dn;
            try {
                const found = await ldapSearchAsync(req.session.adUrl, req.session.adUser, req.session.adPass, BASE_DN, `(sAMAccountName=${safeSam})`, ['dn']);
                if (found?.[0]?.dn) liveDN = found[0].dn;
            } catch(e) { /* fallback to cache DN */ }
            
            // Генерируем латинский CN из displayName
            const parts = (u.displayName || '').trim().split(/\s+/);
            const sn = parts[0] || '';
            const gn = parts[1] || '';
            const trSn = tr(sn).replace(/^./, c => c.toUpperCase());
            const trGn = tr(gn).replace(/^./, c => c.toUpperCase());
            let newCN = `${trSn} ${trGn}`.trim();
            if (!newCN) { skipped++; continue; }
            
            // Проверка уникальности нового CN
            const cnUpper = newCN.toUpperCase();
            const cnExists = cache.users.some(x => {
                if (x.sAMAccountName === u.sAMAccountName) return false;
                const existingCN = decodeEscapedUtf8DN((x.dn || '').split(',')[0].replace(/^CN=/i, '').trim()).toUpperCase();
                return existingCN === cnUpper;
            });
            if (cnExists) {
                if (/y/i.test(newCN)) newCN = newCN.replace(/y(?!.*y)/i, 'i');
                else if (/i/i.test(newCN)) newCN = newCN.replace(/i(?!.*i)/i, 'e');
                else if (/e/i.test(newCN)) newCN = newCN.replace(/e(?!.*e)/i, 'a');
                else newCN = newCN + '2';
            }
            
            const newRDN = `CN=${newCN}`;
            const pwdFile = createPasswordFile(req.session);
            const ldifFile = '/tmp/fixcn_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6) + '.ldif';
            const decodedLiveDN = decodeEscapedUtf8DN(liveDN);
            const ldif = `dn: ${decodedLiveDN}\nchangetype: modrdn\nnewrdn: ${newRDN}\ndeleteoldrdn: 1\n`;
            fs.writeFileSync(ldifFile, ldif);
            
            try {
                const out = execSync(`ldapmodify -x -H ${req.session.adUrl} -D "${req.session.adUser}" -y ${pwdFile} -f ${ldifFile}`, { encoding: 'utf-8', timeout: 15000, env: ENV });
                if (out.trim()) log('DEBUG', `FIX-CN output: ${out.substring(0, 100)}`);
                log('OK', `FIX-CN: ${u.sAMAccountName}: ${decodedCN.substring(0, 30)} → ${newCN}`);
                results.push({ login: u.sAMAccountName, old: decodedCN.substring(0, 40), new: newCN, status: 'ok' });
                fixed++;
            } catch(e) {
                const errOut = (e.stdout || '') + (e.stderr || '');
                log('WARN', `FIX-CN failed: ${u.sAMAccountName}: ${sanitize(errOut || e.message, req.session.adPass)}`);
                results.push({ login: u.sAMAccountName, old: decodedCN.substring(0, 40), new: newCN, status: 'failed', error: (errOut || e.message).substring(0, 150) });
                failed++;
            }
            try { fs.unlinkSync(ldifFile); } catch(e) {}
            try { fs.unlinkSync(pwdFile); } catch(e) {}
        } catch(e) {
            failed++;
        }
    }
    
    if (fixed > 0) await getADData(req.session.adUser, req.session.adPass, req.session.adUrl);
    res.json({ fixed, skipped, failed, total: cache.users.length, results: results.slice(0, 500) });
});

// ─── SMS-AUTH PROXY ────────────────────────────────────────────────
const http = require('http');
const SMS_AUTH_URL = 'http://10.5.2.74:5000';
const SMS_AUTH_HOST = '10.5.2.74';
const SMS_AUTH_PORT = 5000;

function proxySmsAuth(req, res) {
  const options = {
    hostname: SMS_AUTH_HOST,
    port: SMS_AUTH_PORT,
    path: req.url,
    method: req.method,
    headers: { ...req.headers, host: SMS_AUTH_HOST }
  };
  const proxyReq = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });
  proxyReq.on('error', () => res.status(502).json({ error: 'SMS auth server unavailable' }));
  if (req.body) proxyReq.write(JSON.stringify(req.body));
  req.pipe(proxyReq);
}

app.get('/api/sms-auth/history', isAuth, proxySmsAuth);
app.get('/api/sms-auth/stats', isAuth, proxySmsAuth);
app.get('/api/sms-auth/reset', isAuth, proxySmsAuth);
app.post('/api/sms-auth/reset', isAuth, (req, res) => {
  const options = {
    hostname: SMS_AUTH_HOST,
    port: SMS_AUTH_PORT,
    path: '/api/sms-auth/reset',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(JSON.stringify(req.body || {}))
    }
  };
  const proxyReq = http.request(options, (proxyRes) => {
    let data = '';
    proxyRes.on('data', chunk => data += chunk);
    proxyRes.on('end', () => {
      try { res.json(JSON.parse(data)); } catch(e) { res.status(502).json({ error: 'SMS auth error' }); }
    });
  });
  proxyReq.on('error', () => res.status(502).json({ error: 'SMS auth server unavailable' }));
  proxyReq.write(JSON.stringify(req.body || {}));
  proxyReq.end();
});

// ─── START ────────────────────────────────────────────────────────
app.listen(PORT, '0.0.0.0', () => {
    log('OK', `╔══════════════════════════════════════════╗`);
    log('OK', `║  AD Manager V3.1 ЗАПУЩЕН               ║`);
    log('OK', `║  Порт: ${String(PORT).padEnd(34)}║`);
    log('OK', `║  Фронтенд: http://10.1.17.128:8089     ║`);
    log('OK', `║  Дата: ${mskISO().substring(0, 19).padEnd(34)}║`);
    log('OK', `╚══════════════════════════════════════════╝`);
});
