<?php
// sync_ad21_to_ad250.php - Синхронизация статусов Enabled/Disabled между доменами
$ad21 = ldap_connect("ldap://10.1.20.21");
$ad250 = ldap_connect("ldap://10.0.1.250");

ldap_set_option($ad21, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_set_option($ad250, LDAP_OPT_PROTOCOL_VERSION, 3);

if (!@ldap_bind($ad21, "rusagroeco\\bitrix_ad", "Confirmation1709")) die("Bind AD 21 failed");
if (!@ldap_bind($ad250, "Administrator@sync.rusagroeco.ru", "Admin@2026Prostory!")) die("Bind AD 250 failed");

echo "Fetching active users from AD 21...\n";
$active21 = [];
$cookie = '';
do {
    $controls = [['oid' => LDAP_CONTROL_PAGEDRESULTS, 'value' => ['size' => 1000, 'cookie' => $cookie]]];
    $res = ldap_search($ad21, "DC=rusagroeco,DC=ru", "(&(objectClass=user)(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))", ['samaccountname'], 0, 0, 0, LDAP_DEREF_NEVER, $controls);
    $data = ldap_get_entries($ad21, $res);
    for ($i=0; $i<$data['count']; $i++) $active21[strtolower($data[$i]['samaccountname'][0])] = true;
    ldap_parse_result($ad21, $res, $err, $dn, $msg, $refs, $ctrls);
    $cookie = $ctrls[LDAP_CONTROL_PAGEDRESULTS]['value']['cookie'] ?? '';
} while ($cookie);

echo "Checking AD 250 and deactivating retired users...\n";
$search250 = ldap_search($ad250, "OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru", "(&(objectClass=user)(objectCategory=person))");
$data250 = ldap_get_entries($ad250, $search250);

for ($i=0; $i<$data250['count']; $i++) {
    $login = strtolower($data250[$i]['samaccountname'][0]);
    $dn = $data250[$i]['dn'];
    
    if (!isset($active21[$login])) {
        // Пользователь не активен в 21-й или удален. Выключаем в 250-й.
        $uac = 514; // 512 (Normal) + 2 (Disabled)
        if (ldap_modify($ad250, $dn, ['useraccountcontrol' => $uac])) {
            echo "[DISABLED] $login in AD 250 (because inactive in AD 21)\n";
        }
    }
}
echo "Sync Complete.\n";
