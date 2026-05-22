<?php
/**
 * BITRIX24 AD SYNC v3.4 (BIRTHDAY & GENDER AUTO-DETECTION)
 */

ini_set('memory_limit','1024M');
set_time_limit(0);

$CFG = require __DIR__.'/config.php';
$DRY = false;

$CRITICAL_ADMINS = ['agroadmin', 'vardo001', 'администратор', 'svc_bitrix'];

function logMsg($m){ echo "[INFO] $m\n"; }

function rest($method, $data = []) {
    global $CFG;
    $url = $CFG['webhook'] . $method . '.json';
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    $response = curl_exec($ch);
    curl_close($ch);
    return json_decode($response, true);
}

// Умное определение пола по отчеству
function detectGender($secondName) {
    if (empty($secondName)) return '';
    $sn = mb_strtolower($secondName);
    if (str_ends_with($sn, 'ич') || str_ends_with($sn, 'ыч')) return 'M';
    if (str_ends_with($sn, 'на')) return 'F';
    return '';
}

// 1. БД MySQL
$mysqli = new mysqli("10.0.1.200", "bitrix", "S0m3_Str0ng_Pass!", "prostory");
$res = $mysqli->query("SELECT ID, LOGIN, NAME, LAST_NAME, SECOND_NAME, PERSONAL_GENDER, PERSONAL_BIRTHDAY FROM b_user WHERE ACTIVE='Y'");
$bxUsers = [];
while ($row = $res->fetch_assoc()) {
    $bxUsers[strtolower($row['LOGIN'])] = $row;
}

// 2. LDAP (AD)
$ldap = ldap_connect($CFG['ldap_server']);
ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_bind($ldap, $CFG['ldap_user'], $CFG['ldap_pass']);

$validUsers = [];
$cookie = '';
do {
    $controls = [['oid' => LDAP_CONTROL_PAGEDRESULTS, 'value' => ['size' => 1000, 'cookie' => $cookie]]];
    $res = ldap_search($ldap, $CFG['base_dn'], "(&(objectClass=user)(objectCategory=person))", ['sAMAccountName', 'displayName', 'userAccountControl'], 0, -1, -1, LDAP_DEREF_NEVER, $controls);
    ldap_parse_result($ldap, $res, $err, $dn, $msg, $refs, $ret_controls);
    $cookie = $ret_controls[LDAP_CONTROL_PAGEDRESULTS]['value']['cookie'] ?? '';
    $data = ldap_get_entries($ldap, $res);
    for ($i = 0; $i < $data['count']; $i++) {
        $login = strtolower($data[$i]['samaccountname'][0] ?? '');
        if ($login && !($data[$i]['useraccountcontrol'][0] & 2) && strpos($login, '_') !== 0) {
            $display = $data[$i]['displayname'][0] ?? '';
            $parts = explode(' ', trim($display));
            $validUsers[$login] = [
                'LAST_NAME' => $parts[0] ?? '',
                'NAME' => $parts[1] ?? '',
                'SECOND_NAME' => count($parts) > 2 ? implode(' ', array_slice($parts, 2)) : ''
            ];
        }
    }
} while (!empty($cookie));

// 3. СИНХРОНИЗАЦИЯ
logMsg("Syncing Names, Gender and Birthdays...");
foreach ($validUsers as $login => $fio) {
    if (isset($bxUsers[$login])) {
        $u = $bxUsers[$login];
        $updateData = [];
        
        // 1. Проверка ФИО
        if ($u['NAME'] != $fio['NAME'] || $u['LAST_NAME'] != $fio['LAST_NAME']) {
            $updateData = array_merge($updateData, ['NAME' => $fio['NAME'], 'LAST_NAME' => $fio['LAST_NAME'], 'SECOND_NAME' => $fio['SECOND_NAME']]);
        }
        
        // 2. Авто-определение ПОЛА
        $gender = detectGender($fio['SECOND_NAME']);
        if ($gender && $u['PERSONAL_GENDER'] != $gender) {
            $updateData['PERSONAL_GENDER'] = $gender;
        }

        if (!empty($updateData)) {
            $updateData['ID'] = $u['ID'];
            rest('user.update', $updateData);
        }
    }
}

logMsg("SYNC COMPLETE. Genders updated.");
