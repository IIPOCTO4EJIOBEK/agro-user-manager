<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
$_SERVER['DOCUMENT_ROOT'] = '/home/bitrix/www';
require($_SERVER['DOCUMENT_ROOT'] . '/bitrix/modules/main/include/prolog_before.php');

$ldap = ldap_connect("ldap://10.1.20.21");
ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
if (!@ldap_bind($ldap, "rusagroeco\\bitrix_ad", "Confirmation1709")) {
    die("Cannot connect to AD 21");
}

echo "Connected to AD 21. Fetching all active users...\n";
$active_ad_logins = [];
$cookie = '';
do {
    $controls = [['oid' => LDAP_CONTROL_PAGEDRESULTS, 'value' => ['size' => 1000, 'cookie' => $cookie]]];
    $res = ldap_search($ldap, "DC=rusagroeco,DC=ru", "(&(objectClass=user)(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))", ['samaccountname'], 0, 0, 0, LDAP_DEREF_NEVER, $controls);
    if (!$res) break;
    $data = ldap_get_entries($ldap, $res);
    for ($i = 0; $i < $data['count']; $i++) {
        if (!empty($data[$i]['samaccountname'][0])) {
            $active_ad_logins[strtolower($data[$i]['samaccountname'][0])] = true;
        }
    }
    ldap_parse_result($ldap, $res, $err, $dn, $msg, $refs, $ret_controls);
    $cookie = $ret_controls[LDAP_CONTROL_PAGEDRESULTS]['value']['cookie'] ?? '';
} while (!empty($cookie));

echo "Found " . count($active_ad_logins) . " active users in AD 21.\n";

echo "Deactivating Bitrix users missing in AD 21...\n";
$res = CUser::GetList($by='ID', $ord='ASC', ['ACTIVE' => 'Y']);
$deactivated = 0;
while ($u = $res->Fetch()) {
    if ($u['ID'] <= 1) continue;
    if (in_array($u['LOGIN'], ['agroadmin', 'vardo001', 'admin'])) continue;
    if (in_array($u['EXTERNAL_AUTH_ID'], ['bot', 'email'])) continue;
    
    $login = strtolower($u['LOGIN']);
    if (!isset($active_ad_logins[$login])) {
        (new CUser)->Update($u['ID'], ['ACTIVE' => 'N']);
        $deactivated++;
    }
}
echo "Total deactivated: $deactivated\n";
