<?php
$ldap = ldap_connect("ldap://10.1.20.21");
ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_bind($ldap, "rusagroeco\bitrix_ad", "Confirmation1709");

$pageSize = 1000;
$cookie = '';
$total_active = 0;
$total_disabled = 0;

do {
    ldap_control_paged_result($ldap, $pageSize, true, $cookie);
    $res = ldap_search($ldap, "DC=rusagroeco,DC=ru", "(&(objectClass=user)(objectCategory=person))", ["userAccountControl"]);
    if (!$res) break;
    $data = ldap_get_entries($ldap, $res);
    for ($i = 0; $i < $data['count']; $i++) {
        $uac = $data[$i]['useraccountcontrol'][0];
        if ($uac & 2) {
            $total_disabled++;
        } else {
            $total_active++;
        }
    }
    ldap_control_paged_result_response($ldap, $res, $cookie);
} while ($cookie !== null && $cookie != '');

echo "TOTAL LDAP USERS: " . ($total_active + $total_disabled) . "
";
echo "LDAP ACTIVE: $total_active
";
echo "LDAP DISABLED: $total_disabled
";
?>
