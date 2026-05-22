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

$res = CUser::GetList($by='ID', $ord='ASC', ['ACTIVE' => 'Y']);
$deactivated = 0;

while ($u = $res->Fetch()) {
    if ($u['ID'] <= 1) continue; // Skip admin
    if (in_array($u['LOGIN'], ['agroadmin', 'vardo001'])) continue;
    if ($u['EXTERNAL_AUTH_ID'] == 'bot' || $u['EXTERNAL_AUTH_ID'] == 'email') continue;

    $login = $u['LOGIN'];
    $search = @ldap_search($ldap, "DC=rusagroeco,DC=ru", "(&(objectClass=user)(objectCategory=person)(sAMAccountName=$login))");
    
    $should_deactivate = false;
    
    if ($search) {
        $data = ldap_get_entries($ldap, $search);
        if ($data['count'] > 0) {
            $uac = $data[0]['useraccountcontrol'][0];
            if ($uac & 2) {
                // Disabled in AD 21
                $should_deactivate = true;
                echo "User $login is DISABLED in AD 21. Deactivating...\n";
            }
        } else {
            // Not found in AD 21
            $should_deactivate = true;
            echo "User $login NOT FOUND in AD 21. Deactivating...\n";
        }
    } else {
        $should_deactivate = true;
        echo "User $login NOT FOUND in AD 21 (search failed). Deactivating...\n";
    }

    if ($should_deactivate) {
        $user = new CUser;
        $user->Update($u['ID'], ['ACTIVE' => 'N']);
        $deactivated++;
    }
}

echo "Total deactivated based on AD 21: $deactivated\n";
