const express = require('express');
const cors = require('cors');
const session = require('express-session');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { execSync } = require('child_process');
const ldap = require('ldapjs');
const fs = require('fs');
const iconv = require('iconv-lite');
const { parse } = require('csv-parse/sync');

// Escape DN components to prevent LDAP injection
function escapeDN(val) { return (val||'').replace(/[\\,"+<>;#=]/g, '\\$&'); }
// Escape HTML to prevent XSS
function escapeHtml(val) { return (val||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

const app = express();
const PORT = 4001;

// Security middleware
app.use(helmet({ contentSecurityPolicy: false })); // CSP off for inline scripts
app.use(cors({ origin: ['http://10.1.17.128', 'http://10.1.17.128:8080', 'http://10.1.17.128:80', 'http://localhost:8080', 'http://localhost'], credentials: true }));
app.use(express.json({ limit: '10mb' }));
app.use(session({ secret: process.env.SESSION_SECRET || require('crypto').randomBytes(32).toString('hex'), resave: false, saveUninitialized: false, cookie: { secure: false, httpOnly: true, sameSite: 'lax', maxAge: 8 * 60 * 60 * 1000 } }));

// Rate limiting: 10 login attempts per 15 min
const loginLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 10, message: { error: 'Too many login attempts, try later' } });
app.use('/auth/login', loginLimiter);

const BASE_DN = 'DC=rusagroeco,DC=ru';
const ENV = { ...process.env, LDAPTLS_REQCERT: 'never' };

function log(m) { 
    const msg = new Date().toISOString() + ' [INFO] ' + m + '\n';
    console.log(msg);
    try { fs.appendFileSync('/opt/agro-user-manager-v2/logs/app.log', msg); } catch (e) {}
}

const tr = (t) => {
    if (!t) return '';
    const m = {'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','ё':'yo','ж':'zh','з':'z','и':'i','й':'y','к':'k','л':'l','м':'m','н':'n','о':'o','п':'p','р':'r','с':'s','т':'t','у':'u','ф':'f','х':'h','ц':'ts','ч':'ch','ш':'sh','щ':'shch','ъ':'','ы':'y','ь':'','э':'e','ю':'yu','я':'ya'};
    return t.toLowerCase().split('').map(c => m[c] || c).join('');
};

function isAuth(req, res, next) { if (req.session && req.session.authenticated) return next(); res.status(401).send(); }
function decode(s) { try { return Buffer.from(s, 'base64').toString('utf8'); } catch(e) { return s; } }

function sanitize(msg, pass) {
    if (!msg) return msg;
    let clean = msg;
    if (pass) {
        const escapedPass = pass.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        clean = clean.replace(new RegExp(escapedPass, 'g'), '********');
    }
    return clean.replace(/-w\s+"[^"]+"/g, '-w "********"').replace(/-w\s+'[^']+'/g, '-w "********"');
}

const ABBREV = [
    ['чрезвычайных ситуаций', 'ЧС'],
    ['Ростовской области', 'РО'],
    ['Республики Калмыкия', 'РК'],
    ['Республика Калмыкия', 'РК'],
    ['информационно-технологической', 'ИТ'],
    ['информационно-технологического', 'ИТ'],
    ['информационно-технологических', 'ИТ'],
    ['информационно-технологический', 'ИТ'],
    ['информационно-технологическая', 'ИТ'],
    ['информационно-технологические', 'ИТ'],
    ['информационно-технологическому', 'ИТ'],
    ['сельскохозяйствен', 'с/х'],
    ['недвижимым имуществом', 'недв.имуществом'],
    ['недвижимого имущества', 'недв.имущества'],
];
function abbrev(s) { for (const [f, t] of ABBREV) s = s.replace(f, t); return s; }

function toLdif(attr, val) {
    if (val === undefined || val === null) return '';
    const needsB64 = /[^\x00-\x7F]/.test(val);
    if (needsB64) return attr + ':: ' + Buffer.from(val).toString('base64');
    return attr + ': ' + val;
}

let cache = { users: [], ous: [], depts: [], comps: [], titles: [], locations: [], offices: [], descriptions: [], assistants: [], dbStats: {}, syncing: false, lastUpdate: 0 };

function getADData(user, pass, adUrl) {
    cache.syncing = true;
    log('AD SCAN V2.6: Starting full database crawl...');
    const pwdFile = '/tmp/pw_' + Date.now() + Math.random();
    try {
        fs.writeFileSync(pwdFile, pass, { mode: 0o600 });
        const attrs = ['sAMAccountName', 'mail', 'displayName', 'department', 'company', 'title', 'l', 'st', 'manager', 'info', 'telephoneNumber', 'mobile', 'homePhone', 'extensionAttribute1', 'extensionAttribute2', 'extensionAttribute3', 'assistant', 'userAccountControl', 'physicalDeliveryOfficeName', 'description', 'homeMDB', 'sn', 'givenName'];
        const cmd = `ldapsearch -x -H ${adUrl} -D "${user}" -y ${pwdFile} -b "${BASE_DN}" "(&(objectClass=user)(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2))(!(servicePrincipalName=*))(!(cn=*Mailbox*))(!(description=*service*)))" ${attrs.join(' ')} -E pr=2000/noprompt -LLL`;
        const out = execSync(cmd, { encoding: 'utf-8', maxBuffer: 100 * 1024 * 1024, env: ENV });
        
        const depts = new Set(), comps = new Set(), users = [], titles = new Set(), locs = new Set(), offices = new Set(), descs = new Set(), assts = new Set();
        const dbStats = { DB01:0, DB02:0, DB03:0, DB04:0, DB05:0, DB06:0, DB07:0, DB08:0, DB09:0, DB10:0, DB11:0, DB12:0 };
        
        const rawEntries = out.split('\n\n');
        for (const entry of rawEntries) {
            if (!entry.trim()) continue;
            const obj = {};
            const lines = entry.replace(/\n\s+/g, '').split('\n');
            for (const l of lines) {
                if (!l.includes(': ')) continue;
                let [k, v] = l.split(': ', 2);
                const isB64 = k.endsWith(':'); if (isB64) k = k.slice(0, -1);
                const val = isB64 ? decode(v.trim()) : v.trim();
                obj[k] = val;
                
                if (k === 'department' && val) depts.add(val);
                if (k === 'company' && val) comps.add(val);
                if (k === 'title' && val) titles.add(val);
                if (k === 'l' && val) locs.add(val);
                if (k === 'physicalDeliveryOfficeName' && val) offices.add(val);
                if (k === 'description' && val) descs.add(val);
                if (k === 'assistant' && val) assts.add(val);
                if (k === 'homeMDB') {
                    const m = val.match(/CN=(DB\d{2})/i);
                    if (m && dbStats[m[1]] !== undefined) dbStats[m[1]]++;
                }
            }
            if (obj.sAMAccountName) users.push(obj);
        }
        
        const ouOut = execSync(`ldapsearch -x -H ${adUrl} -D "${user}" -y ${pwdFile} -b "${BASE_DN}" "(objectClass=organizationalUnit)" ou description -LLL`, { encoding: 'utf-8', env: ENV });
        const ous = [];
        for (const entry of ouOut.split('\n\n')) {
            let d = '', n = '', desc = '';
            for (const l of entry.replace(/\n\s+/g, '').split('\n')) {
                if (l.startsWith('dn: ')) d = l.substring(4).trim();
                if (l.startsWith('ou: ')) n = l.substring(4).trim();
                if (l.startsWith('ou:: ')) n = decode(l.substring(5).trim());
                if (l.startsWith('description: ')) desc = l.substring(13).trim();
                if (l.startsWith('description:: ')) desc = decode(l.substring(14).trim());
            }
            if (d) ous.push({ name: n || 'OU', dn: d, desc });
        }
        fs.unlinkSync(pwdFile);
        cache = { 
            users: users.sort((a,b)=>(a.displayName||'').localeCompare(b.displayName||'')), 
            ous: ous.sort((a,b)=>a.dn.length - b.dn.length),
            depts: Array.from(depts).sort(), 
            comps: Array.from(comps).sort(), 
            titles: Array.from(titles).sort(),
            locations: Array.from(locs).sort(),
            offices: Array.from(offices).sort(),
            descriptions: Array.from(descs).sort(),
            assistants: Array.from(assts).sort(),
            dbStats, syncing: false, lastUpdate: Date.now()
        };
        log('AD SCAN V2.6: Finished. Users found: ' + users.length);
    } catch(e) { 
        if (fs.existsSync(pwdFile)) fs.unlinkSync(pwdFile);
        cache.syncing = false;
        log('AD SCAN ERROR: ' + sanitize(e.message, pass)); 
    }
}

app.post('/auth/login', (req, res) => {
    let { username, password, adIp } = req.body;
    log(`LOGIN: Attempt for ${username} on ${adIp || 'default IP'}`);
    const adUser = username.includes('@') ? username : username + '@rusagroeco.ru';
    const adUrl = 'ldaps://' + (adIp || '10.1.20.21');
    const client = ldap.createClient({ url: adUrl, tlsOptions: { rejectUnauthorized: false } });
    client.bind(adUser, password, (err) => {
        if (err) { 
            log(`LOGIN ERROR: ${err.message}`);
            client.destroy(); 
            return res.status(401).json({error: sanitize(err.message, password)}); 
        }
        log(`LOGIN SUCCESS: ${adUser}`);
        req.session.authenticated = true;
        req.session.adUser = adUser; req.session.adPass = password; req.session.adUrl = adUrl;
        res.json({success: true}); client.unbind();
        setTimeout(() => getADData(adUser, password, adUrl), 100);
    });
});

app.get('/auth/check', (req, res) => res.json({ authenticated: !!req.session?.authenticated }));
app.post('/auth/logout', (req, res) => { req.session.destroy(() => res.json({success: true})); });

app.get('/api/data', isAuth, (req, res) => {
    log(`GET DATA: Users=${cache.users.length}, OUs=${cache.ous.length}`);
    res.json(cache);
});

const createUserInternal = (d, session) => {
    log(`CREATE USER: Started for ${d.displayName || 'unknown'}`);
    const parts = (d.displayName || '').trim().split(/\s+/);
    const sn = (d.sn || parts[0] || '').trim();
    const gn = (d.givenName || parts[1] || '').trim();
    const pn = (d.patronymic || parts[2] || '').trim();
    // Transliterated first/last name for LDAP sn/givenName
    const cap = (s) => s ? s[0].toUpperCase() + s.slice(1) : '';
    const trSn = cap(tr(sn));
    const trGn = cap(tr(gn));
    let login = (d.sam || (tr(sn) + '.' + (tr(gn)[0]||'') + (tr(pn)[0]||'')).toLowerCase().replace(/[^a-z0-9.]/g, '')).trim();
    
    // Truncate long fields to AD limit (64 chars)
    const t64 = (s) => { s = abbrev(s || ''); return s.length > 64 ? s.substring(0, 64) : s; };
    if (!d.siteOU) {
        log(`CREATE USER ERROR: Missing siteOU for ${d.displayName}`);
        return { success: false, error: 'Не указано подразделение (OU)' };
    }

    const pwdFile = '/tmp/pw_' + Date.now() + Math.random();
    try {
        fs.writeFileSync(pwdFile, session.adPass, { mode: 0o600 });
        // Don't double OU=Users if siteOU already starts with it
        let siteOU = d.siteOU;
        if (!siteOU.toUpperCase().startsWith('OU=USERS,') && !siteOU.toUpperCase().includes(',OU=USERS,')) {
            siteOU = `OU=Users,${d.siteOU}`;
        }
        const userDN = `CN=${escapeDN(d.displayName)},${siteOU}`;
        log(`CREATE USER: Target DN = ${userDN}`);

        let ldif = `dn: ${escapedDN}\nobjectClass: top\nobjectClass: person\nobjectClass: organizationalPerson\nobjectClass: user\n`;
        ldif += `${toLdif('cn', d.displayName)}\n${toLdif('displayName', d.displayName)}\n`;
        if (trSn) ldif += `sn: ${trSn}\n`;
        if (trGn) ldif += `givenName: ${trGn}\n`;
        ldif += `sAMAccountName: ${login}\nuserPrincipalName: ${login}@ahprostory.ru\n`;
        
        const attrMap = { 
            title: t64(d.title), department: t64(d.department), company: t64(d.company), 
            l: t64(d.l), st: t64(d.st), info: d.info, mail: (d.mail && d.mail !== '0') ? d.mail : (login + '@ahprostory.ru'), 
            telephoneNumber: d.telephoneNumber, mobile: d.mobile, homePhone: d.homePhone, 
            extensionAttribute1: sn, extensionAttribute2: gn, extensionAttribute3: pn, 
            assistant: d.assistant, description: d.description, physicalDeliveryOfficeName: t64(d.office)
        };
        for (const [k, v] of Object.entries(attrMap)) if (v) ldif += `${toLdif(k, v)}\n`;
        if (d.manager && !/^ваканс|^vacanc/i.test(d.manager)) {
            const mgrObj = cache.users.find(u => u.displayName === d.manager || u.dn === d.manager);
            if (mgrObj) ldif += `manager: ${mgrObj.dn}\n`;
        }

        ldif += 'userAccountControl: 514\n';
        const lp = `/tmp/add_${Date.now()}.ldif`; fs.writeFileSync(lp, ldif);
        log(`CREATE USER: Running ldapadd...`);
        execSync(`ldapadd -x -H ${session.adUrl} -D "${session.adUser}" -y ${pwdFile} -f ${lp}`, { env: ENV });
        
        const pass = d.password || `Agro${Math.random().toString(36).substring(2, 10)}!`;
        const pwdBase64 = Buffer.from(`"${pass}"`, 'utf16le').toString('base64');
        const enableLdif = `dn: ${userDN}\nchangetype: modify\nreplace: unicodePwd\nunicodePwd:: ${pwdBase64}\n-\nreplace: userAccountControl\nuserAccountControl: 512\n-\n`;
        const elp = `/tmp/en_${Date.now()}.ldif`; fs.writeFileSync(elp, enableLdif);
        log(`CREATE USER: Enabling user and setting password...`);
        execSync(`ldapmodify -x -H ${session.adUrl} -D "${session.adUser}" -y ${pwdFile} -f ${elp}`, { env: ENV });
        
        if (d.createMail) {
            log(`CREATE USER: Enabling Exchange mailbox...`);
            try { execSync(`ssh -o StrictHostKeyChecking=no Administrator@10.2.27.118 'powershell "Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010; Enable-Mailbox -Identity ${login} -Database ${d.exchDb || 'DB01'}"'`, { env: ENV }); } catch (err) { log('Exchange Error: ' + err.message); }
        }
        // Add to VPN group (only if checkbox checked)
        if (d.addVpn) {
            try {
                const vpnGroup = 'CN=AD_VPN_Users,OU=Service Groups,OU=Groups,DC=rusagroeco,DC=ru';
                const vpnLdif = `dn: ${vpnGroup}\nchangetype: modify\nadd: member\nmember: ${userDN}\n-\n`;
                const vlp = `/tmp/vpn_${Date.now()}.ldif`; fs.writeFileSync(vlp, vpnLdif);
                execSync(`ldapmodify -x -H ${session.adUrl} -D "${session.adUser}" -y ${pwdFile} -f ${vlp}`, { env: ENV });
                log(`CREATE USER: Added to VPN group`);
            } catch (err) { log('VPN group error: ' + err.message); }
        }
        log(`CREATE USER SUCCESS: ${login}`);
        return { success: true, login, password: pass, email: (d.mail && d.mail !== '0') ? d.mail : (login + '@ahprostory.ru'), displayName: d.displayName };
    } catch(e) { 
        log(`CREATE USER ERROR: ${e.message}`);
        return { success: false, error: sanitize(e.message, session.adPass) }; 
    }
    finally { if (fs.existsSync(pwdFile)) fs.unlinkSync(pwdFile); }
};

app.post('/api/create-user', isAuth, (req, res) => {
    log(`API: POST /api/create-user`);
    res.json(createUserInternal(req.body, req.session));
});

app.post('/api/apply-batch', isAuth, (req, res) => {
    const { actions } = req.body;
    log(`API: POST /api/apply-batch, actions=${actions?.length}`);
    const results = [];
    const pwdFile = '/tmp/pw_b_' + Date.now();
    fs.writeFileSync(pwdFile, req.session.adPass);
    try {
        for (const action of actions) {
            try {
                if (action.type === 'update') {
                    const d = action.data;
                    log(`BATCH: Updating ${action.dn}`);
                    let ldif = `dn: ${action.dn}\nchangetype: modify\n`;
                    const attrs = { displayName: 'displayName', title: 'title', department: 'department', company: 'company', l: 'l', st: 'st', info: 'info', mail: 'mail', telephoneNumber: 'telephoneNumber', mobile: 'mobile', homePhone: 'homePhone', sn: 'extensionAttribute1', givenName: 'extensionAttribute2', patronymic: 'extensionAttribute3', assistant: 'assistant', description: 'description', office: 'physicalDeliveryOfficeName' };
                    const LIMIT64 = ['title','department','company','l','st','office'];
                    for (const [key, attr] of Object.entries(attrs)) {
                        let v = d[key];
                        // Skip empty values — don't delete existing AD data
                        if (!v) continue;
                        // Abbreviate + truncate AD-limited fields to 64 chars
                        v = abbrev(v);
                        if (LIMIT64.includes(key)) v = v.substring(0, 64);
                        ldif += `replace: ${attr}\n${toLdif(attr, v) + '\n-'}\n`;
                    }
                    if (d.manager) {
                        if (/^ваканс|^vacanc/i.test(d.manager)) {
                            ldif += 'replace: manager\n-\n';
                        } else {
                        const mgrObj = cache.users.find(u => u.displayName === d.manager || u.dn === d.manager);
                        if (mgrObj) ldif += `replace: manager\nmanager: ${mgrObj.dn}\n-\n`;
                        }
                    }
                    if (d.enabled !== undefined) {
                        const existing = cache.users.find(u => u.dn === action.dn);
                        if (existing) {
                            let uac = (parseInt(existing.userAccountControl) & ~2) | (d.enabled ? 0 : 2);
                            ldif += `replace: userAccountControl\nuserAccountControl: ${uac}\n-\n`;
                        }
                    }
                    const lp = `/tmp/m_${Date.now()}.ldif`; fs.writeFileSync(lp, ldif);
                    execSync(`ldapmodify -x -H ${req.session.adUrl} -D "${req.session.adUser}" -y ${pwdFile} -f ${lp}`, { env: ENV });
                    if (action.newOU && !action.dn.toLowerCase().includes(action.newOU.toLowerCase())) {
                        const newRDN = action.dn.split(',')[0];
                        execSync(`ldapmodrdn -x -H ${req.session.adUrl} -D "${req.session.adUser}" -y ${pwdFile} -s "${action.newOU}" "${action.dn}" "${newRDN}"`, { env: ENV });
                    }
                    results.push({ name: d.displayName, success: true });
                } else if (action.type === 'create') {
                    results.push({ name: action.data.displayName, ...createUserInternal(action.data, req.session) });
                }
            } catch (err) { 
                log(`BATCH ERROR: ${action.dn || 'unknown'}: ${err.message}`);
                results.push({ name: action.data?.displayName || action.dn, success: false, error: err.message }); 
            }
        }
        res.json({ success: true, results });
    } finally { if (fs.existsSync(pwdFile)) fs.unlinkSync(pwdFile); }
});

const VPN_GROUP = 'CN=AD_VPN_Users,OU=Service Groups,OU=Groups,DC=rusagroeco,DC=ru';

app.post('/api/vpn-add', isAuth, (req, res) => {
    const { dn } = req.body;
    log(`VPN ADD: Adding ${dn} to VPN group`);
    const pwdFile = '/tmp/pw_v_' + Date.now();
    try {
        fs.writeFileSync(pwdFile, req.session.adPass);
        const vpnLdif = `dn: ${VPN_GROUP}\nchangetype: modify\nadd: member\nmember: ${dn}\n-\n`;
        const vlp = `/tmp/vpn_${Date.now()}.ldif`; fs.writeFileSync(vlp, vpnLdif);
        execSync(`ldapmodify -x -H ${req.session.adUrl} -D "${req.session.adUser}" -y ${pwdFile} -f ${vlp}`, { env: ENV });
        log(`VPN ADD: Success for ${dn}`);
        res.json({ success: true });
    } catch (e) { 
        log(`VPN ADD ERROR: ${e.message}`);
        res.status(500).json({ error: e.message }); 
    }
    finally { if (fs.existsSync(pwdFile)) fs.unlinkSync(pwdFile); }
});

app.post('/api/toggle-user', isAuth, (req, res) => {
    const { dn, enable } = req.body;
    const pwdFile = '/tmp/pw_t_' + Date.now();
    try {
        fs.writeFileSync(pwdFile, req.session.adPass);
        const user = cache.users.find(u => u.dn === dn);
        let uac = (parseInt(user.userAccountControl) & ~2) | (enable ? 0 : 2);
        const ldif = `dn: ${dn}\nchangetype: modify\nreplace: userAccountControl\nuserAccountControl: ${uac}\n`;
        const lp = `/tmp/t_${Date.now()}.ldif`; fs.writeFileSync(lp, ldif);
        execSync(`ldapmodify -x -H ${req.session.adUrl} -D "${req.session.adUser}" -y ${pwdFile} -f ${lp}`, { env: ENV });
        res.json({ success: true });
    } catch (e) { res.status(500).json({ error: e.message }); }
    finally { if (fs.existsSync(pwdFile)) fs.unlinkSync(pwdFile); }
});

app.post('/api/compare-csv', isAuth, (req, res) => {
    const { csvData, isBase64 } = req.body;
    try {
        log('COMPARE CSV: Received data, size=' + csvData.length);
        let content = isBase64 ? Buffer.from(csvData, 'base64') : Buffer.from(csvData);
        let decoded = iconv.decode(content, 'win1251');
        if (!decoded.includes(';')) decoded = content.toString('utf-8');
        let del = decoded.includes('\t') ? '\t' : ';';
        log('COMPARE CSV: Using delimiter [' + (del === '\t' ? '\\t' : del) + ']');
        
        // Manual CSV parsing — split by delimiter, pad to header length
        const lines = decoded.trim().split(/\r?\n/);
        const header = lines[0].split(del).map(h => h.trim());
        log('COMPARE CSV: Header cols=' + header.length);
        
        const recs = [];
        for (let i = 1; i < lines.length; i++) {
            const vals = lines[i].split(del);
            // Fix missing Отчество column (common Excel export bug: "Да;;;ФИО" has 3 semicolons but needs 4)
            // Must run BEFORE padding — check original length, not padded
            if (vals.length === 19 && header.length === 20 && (vals[0] === 'Да' || vals[0] === 'Нет')) {
                vals.splice(3, 0, '');  // Insert empty Отчество before ФИО
            }
            // Pad to match header length
            while (vals.length < header.length) vals.push('');
            // If exactly one extra value, merge into last column (common Excel export bug)
            if (vals.length === header.length + 1) {
                vals[header.length - 1] = vals[header.length - 1] + ' ' + vals[header.length];
                vals.length = header.length;
            }
            // Truncate extra values beyond header
            const trimmed = vals.slice(0, header.length);
            const r = {};
            header.forEach((h, idx) => { r[h] = (trimmed[idx] || '').trim(); });
            recs.push(r);
        }
        log('COMPARE CSV: Records parsed: ' + recs.length);
        
        if (recs.length > 0) log('COMPARE CSV: Sample record keys: ' + Object.keys(recs[0]).join(', '));

        const comparisons = recs.map((r, idx) => {
            let sn = (r['Фамилия'] || '').trim();
            let gn = (r['Имя'] || '').trim();
            let pn = (r['Отчество'] || '').trim();
            let fio = (r['ФИО'] || '').trim();

            if (fio && (!sn || !gn)) {
                const p = fio.split(/\s+/);
                if (!sn) sn = p[0] || '';
                if (!gn) gn = p[1] || '';
                if (!pn) pn = p[2] || '';
            } else if (!fio && (sn || gn)) {
                fio = [sn, gn, pn].filter(Boolean).join(' ');
            }

            let login = (r['Логин'] || '').trim();
            if (!login && sn) {
                login = tr(sn);
                if (gn) login += '.' + tr(gn)[0];
                if (pn) login += tr(pn)[0];
                login = login.toLowerCase().replace(/[^a-z0-9.]/g, '');
            }

            let mail = (r['Email'] || '').trim();
            if (!mail && login) {
                mail = login + '@ahprostory.ru';
            }

            const reg = (r['Регион'] || '').trim();
            const comp = (r['Компания'] || '').trim();
            const city = (r['Город'] || '').trim();
            const deptRaw = (r['Отдел'] || '').trim();
            const CITY_REGION = {
                'ростов': 'RND', 'ставропол': 'STV', 'краснодар': 'KRD',
                'москва': 'MSK', 'воронеж': 'VRN', 'нижн': 'NIZ', 'новгород': 'NIZ',
                'волгоград': 'VLC', 'белгород': 'BDN', 'липецк': 'LPK',
            };
            function getParentDN(dn) {
                const parts = dn.split(',').map(p => p.trim());
                return parts.slice(1).join(',');
            }
            let siteOU = '';
            
            if (cache.ous && cache.ous.length > 0) {
                // 1. Same department as existing user → copy their OU
                if (deptRaw && cache.users && cache.users.length) {
                    const sameDept = cache.users.find(u => u.department === deptRaw && u.dn);
                    if (sameDept) siteOU = getParentDN(sameDept.dn);
                }
                // 2. Region code from city
                if (!siteOU && city) {
                    const c = city.toLowerCase();
                    let code = '';
                    for (const [k, v] of Object.entries(CITY_REGION)) { if (c.includes(k)) { code = v; break; } }
                    if (code) {
                        // 3. User with same dept in same region
                        if (deptRaw && cache.users && cache.users.length) {
                            const same = cache.users.find(u => u.department === deptRaw && u.dn && u.dn.toUpperCase().includes('OU=' + code));
                            if (same) siteOU = getParentDN(same.dn);
                        }
                        // 4. Most common parent OU in this region
                        if (!siteOU && cache.users && cache.users.length) {
                            const regionUsers = cache.users.filter(u => u.dn && u.dn.toUpperCase().includes('OU=' + code));
                            if (regionUsers.length > 0) {
                                const cnt = {};
                                for (const u of regionUsers) {
                                    const p = getParentDN(u.dn);
                                    cnt[p] = (cnt[p] || 0) + 1;
                                }
                                siteOU = Object.entries(cnt).sort((a,b)=>b[1]-a[1])[0][0];
                            }
                        }
                    }
                    // 5. OU with Users + region code
                    if (!siteOU && code) {
                        const userOU = cache.ous.find(o => o.dn.toUpperCase().includes('OU=USERS') && o.dn.toUpperCase().includes('OU=' + code));
                        if (userOU) siteOU = userOU.dn;
                    }
                    // 6. Any OU with region code
                    if (!siteOU && code) {
                        const match = cache.ous.find(o => o.dn.toUpperCase().includes('OU=' + code));
                        if (match) siteOU = match.dn;
                    }
                    // 6. Direct name match
                    if (!siteOU) {
                        const match = cache.ous.find(o => o.name === city || o.dn.toLowerCase().includes('ou=' + c + ','));
                        if (match) siteOU = match.dn;
                    }
                }
                if (!siteOU && comp) {
                    const match = cache.ous.find(o => o.name === comp || o.dn.toLowerCase().includes('ou=' + comp.toLowerCase() + ','));
                    if (match) siteOU = match.dn;
                }
                if (!siteOU && reg) {
                    const match = cache.ous.find(o => o.name === reg || o.dn.toLowerCase().includes('ou=' + reg.toLowerCase() + ','));
                    if (match) siteOU = match.dn;
                }
            }

            const inc = { 
                displayName: fio, sam: login, mail: mail, 
                title: abbrev(r['Должность'] || ''), 
                department: abbrev(r['Отдел'] || ''), 
                company: abbrev(comp), st: abbrev(reg), l: abbrev(city), 
                info: r['Дата_Рождения'] || '', telephoneNumber: r['Рабочий_Тел'] || '', mobile: r['Мобильный'] || r['Мобильный_Тел'] || '', 
                homePhone: r['Телефон'] || '', sn: sn, givenName: gn, patronymic: pn, 
                assistant: r['Привязки'] || '', enabled: (r['Активность'] !== 'Нет' && r['Активность'] !== '0'),
                description: r['Описание'] || '', office: abbrev(r['Адрес'] || ''), manager: r['Менеджер'] || '', siteOU: siteOU
            };
            
            const ex = cache.users.find(u => (inc.sam && u.sAMAccountName === inc.sam) || (inc.displayName && u.displayName === inc.displayName));
            if (!ex) return { type: 'new', incoming: inc };
            
            const diffs = {};
            const attrs = { title: 'title', department: 'department', company: 'company', l: 'l', st: 'st', info: 'info', mail: 'mail', telephoneNumber: 'telephoneNumber', mobile: 'mobile', homePhone: 'homePhone', sn: 'extensionAttribute1', givenName: 'extensionAttribute2', patronymic: 'extensionAttribute3', assistant: 'assistant', description: 'description', office: 'physicalDeliveryOfficeName', manager: 'manager' };
            for (const [key, attr] of Object.entries(attrs)) {
                let incVal = inc[key] || '';
                let exVal = ex[attr] || '';
                if (key === 'manager' && exVal && exVal.includes('=')) {
                    const m = cache.users.find(u => u.dn === exVal);
                    exVal = m ? m.displayName : exVal;
                }
                // Only flag diff when CSV has a value (don't flag AD-only data as removable)
                if (incVal && incVal !== String(exVal)) diffs[key] = { old: exVal, new: incVal };
            }
            const exActive = !(parseInt(ex.userAccountControl) & 2);
            if (inc.enabled !== undefined && inc.enabled !== exActive) diffs['enabled'] = { old: exActive, new: inc.enabled };
            if (Object.keys(diffs).length > 0) log('COMPARE DIFF: ' + (inc.displayName || inc.sam) + ' diffs=' + JSON.stringify(diffs));
            return { type: Object.keys(diffs).length > 0 ? 'diff' : 'same', incoming: inc, existing: ex, diffs };
        });
        log('COMPARE CSV: Success, comparisons: ' + comparisons.length);
        res.json({ success: true, comparisons });
    } catch (e) { 
        log('COMPARE CSV ERROR: ' + e.message);
        res.status(500).json({ error: e.message }); 
    }
});

app.get('/api/export-csv', isAuth, (req, res) => {
    let users = cache.users;
    if (req.query.active === 'true') users = users.filter(u => !(parseInt(u.userAccountControl) & 2));
    if (req.query.tech === 'true') users = users.filter(u => (u.sAMAccountName||'').includes('svc_') || (u.description||'').toLowerCase().includes('service') || (u.displayName||'').includes('Mailbox'));
    
    const getMgrName = (dn) => {
        if (!dn) return '';
        const m = cache.users.find(u => u.dn === dn);
        return m ? m.displayName : dn;
    };

    let csv = 'Активность;Фамилия;Имя;Отчество;ФИО;Логин;Email;Должность;Отдел;Компания;Регион;Город;Дата_Рождения;Телефон;Рабочий_Тел;Мобильный;Привязки;Описание;Адрес;Менеджер\n';
    for (const u of users) {
        const parts = (u.displayName||'').trim().split(/\s+/);
        const sn = u.sn || u.extensionAttribute1 || parts[0] || '';
        const gn = u.givenName || u.extensionAttribute2 || parts[1] || '';
        const pn = u.extensionAttribute3 || parts[2] || '';
        const mail = u.mail || (u.sAMAccountName ? u.sAMAccountName + '@ahprostory.ru' : '');
        csv += `${(parseInt(u.userAccountControl)&2)?'Нет':'Да'};${sn};${gn};${pn};${u.displayName||''};${u.sAMAccountName||''};${mail};${u.title||''};${u.department||''};${u.company||''};${u.st||''};${u.l||''};${u.info||''};${u.homePhone||''};${u.telephoneNumber||''};${u.mobile||''};${u.assistant||''};${u.description||''};${u.physicalDeliveryOfficeName||''};${getMgrName(u.manager)}\n`;
    }
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=ad_export_full.csv');
    res.send(iconv.encode(csv, 'win1251'));
});

app.listen(PORT, '0.0.0.0', () => log('V2.6 FINAL started on ' + PORT));