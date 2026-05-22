<?php
// bitrix_ad_sync_v5.php - ПОЛНАЯ АВТОМАТИЗАЦИЯ ИЕРАРХИИ ИЗ AD 250
$_SERVER['DOCUMENT_ROOT'] = '/home/bitrix/www';
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require($_SERVER['DOCUMENT_ROOT'] . '/bitrix/modules/main/include/prolog_before.php');

if (!CModule::IncludeModule('ldap') || !CModule::IncludeModule('iblock')) die("Modules missing");

$CFG = [
    'ldap_server' => 'ldap://10.0.1.250',
    'ldap_user'   => 'Administrator@sync.rusagroeco.ru',
    'ldap_pass'   => 'Admin@2026Prostory!',
    'base_dn'     => 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru',
    'iblock_id'   => 3,
    'server_id'   => 2
];

$EXCLUDE_LOGINS = ['krbtgt', 'svc_', 'admin_', 'test_', 'mailbox'];
$EXCLUDE_STR = ['Агроконсалтинг', 'НКС', 'Президент'];

function isExcluded($u) {
    global $EXCLUDE_LOGINS, $EXCLUDE_STR;
    $login = strtolower($u['samaccountname'][0] ?? '');
    $comp = $u['company'][0] ?? '';
    $dept = $u['department'][0] ?? '';
    foreach ($EXCLUDE_LOGINS as $ex) if (strpos($login, $ex) !== false) return true;
    foreach ($EXCLUDE_STR as $ex) if (strpos($comp, $ex) !== false || strpos($dept, $ex) !== false) return true;
    return false;
}

$ldap = ldap_connect($CFG['ldap_server']);
ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_set_option($ldap, LDAP_OPT_REFERRALS, 0);
ldap_bind($ldap, $CFG['ldap_user'], $CFG['ldap_pass']);

// 1. ПОСТРОЕНИЕ ИЕРАРХИИ ПОДРАЗДЕЛЕНИЙ (OU)
logMsg("Step 1: Building OU Hierarchy...");
$search = ldap_search($ldap, $CFG['base_dn'], "(objectClass=organizationalUnit)", ['ou']);
$entries = ldap_get_entries($ldap, $search);
$bs = new CIBlockSection();
$ou_to_id = [strtolower($CFG['base_dn']) => 1]; // Корень AD = Корень Битрикс (ID 1)

usort($entries, function($a, $b) {
    return substr_count($a['dn'] ?? '', ',') - substr_count($b['dn'] ?? '', ',');
});

foreach ($entries as $entry) {
    if (!isset($entry['dn'])) continue;
    $dn = strtolower($entry['dn']);
    if ($dn == strtolower($CFG['base_dn'])) continue;

    $name = $entry['ou'][0];
    $parent_dn = preg_replace('/^ou=[^,]+,?\s*/i', '', $dn);
    $parent_id = $ou_to_id[$parent_dn] ?? 1;

    $xml_id = "LDAP://" . $CFG['server_id'] . "/" . $entry['dn'];
    
    $res = CIBlockSection::GetList([], ['IBLOCK_ID' => $CFG['iblock_id'], 'XML_ID' => $xml_id], false, ['ID']);
    if ($sect = $res->Fetch()) {
        $sect_id = $sect['ID'];
        $bs->Update($sect_id, ['IBLOCK_SECTION_ID' => $parent_id, 'NAME' => $name, 'ACTIVE' => 'Y']);
    } else {
        $sect_id = $bs->Add(['IBLOCK_ID' => $CFG['iblock_id'], 'IBLOCK_SECTION_ID' => $parent_id, 'NAME' => $name, 'XML_ID' => $xml_id, 'ACTIVE' => 'Y']);
    }
    $ou_to_id[$dn] = $sect_id;
}

// 2. СИНХРОНИЗАЦИЯ ПОЛЬЗОВАТЕЛЕЙ
logMsg("Step 2: Syncing users to their OUs...");
$pageSize = 500; $cookie = ''; $total = 0;
do {
    $controls = [['oid' => LDAP_CONTROL_PAGEDRESULTS, 'value' => ['size' => $pageSize, 'cookie' => $cookie]]];
    $search = ldap_search($ldap, $CFG['base_dn'], "(&(objectClass=user)(objectCategory=person))", [], 0, 0, 0, LDAP_DEREF_NEVER, $controls);
    $entries = ldap_get_entries($ldap, $search);
    for ($i=0; $i < $entries['count']; $i++) {
        $user = $entries[$i];
        $login = $user['samaccountname'][0];
        $dn = strtolower($user['dn']);
        
        // Отдел берем СТРОГО из родительского OU
        $parent_ou_dn = preg_replace('/^cn=[^,]+,?\s*/i', '', $dn);
        $dept_id = $ou_to_id[$parent_ou_dn] ?? 1;

        $active = isExcluded($user) ? 'N' : 'Y';
        $xml_id = "LDAP://" . $CFG['server_id'] . "/" . $user['dn'];

        $arFields = [
            'LOGIN' => $login,
            'NAME' => $user['extensionattribute2'][0] ?? $user['displayname'][0],
            'LAST_NAME' => $user['extensionattribute1'][0] ?? '',
            'SECOND_NAME' => $user['extensionattribute3'][0] ?? '',
            'UF_DEPARTMENT' => [$dept_id],
            'ACTIVE' => $active,
            'XML_ID' => $xml_id,
            'EXTERNAL_AUTH_ID' => 'LDAP#' . $CFG['server_id']
        ];

        $res = CUser::GetList($by, $ord, ['XML_ID' => $xml_id]);
        if ($bx = $res->Fetch()) { (new CUser)->Update($bx['ID'], $arFields); }
        else { (new CUser)->Add($arFields + ['PASSWORD' => randString(12), 'CONFIRM_PASSWORD' => 'skip']); }
        if ($active == 'Y') $total++;
    }
    ldap_parse_result($ldap, $search, $err, $mdn, $emsg, $ref, $ctrls);
    $cookie = $ctrls[LDAP_CONTROL_PAGEDRESULTS]['value']['cookie'] ?? '';
} while ($cookie !== '');

function logMsg($m) { echo "[INFO] $m\n"; }
echo "Finished. Active: $total\n";
