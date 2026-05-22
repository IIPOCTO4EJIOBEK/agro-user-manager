<?php
$ldap = ldap_connect("ldap://10.1.20.21");
ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_bind($ldap, "rusagroeco\bitrix_ad", "Confirmation1709");

$total_active = 0;
$total_disabled = 0;
$cookie = '';

do {
    $controls = [
        [
            'oid' => LDAP_CONTROL_PAGEDRESULTS,
            'value' => [
                'size' => 1000,
                'cookie' => $cookie
            ]
        ]
    ];

    $res = ldap_search($ldap, "DC=rusagroeco,DC=ru", "(&(objectClass=user)(objectCategory=person))", ["userAccountControl"], 0, -1, -1, LDAP_DEREF_NEVER, $controls);
    if (!$res) break;

    ldap_parse_result($ldap, $res, $errcode, $matcheddn, $errmsg, $referrals, $controls);
    if (isset($controls[LDAP_CONTROL_PAGEDRESULTS]['value']['cookie'])) {
        $cookie = $controls[LDAP_CONTROL_PAGEDRESULTS]['value']['cookie'];
    } else {
        $cookie = '';
    }

    $data = ldap_get_entries($ldap, $res);
    for ($i = 0; $i < $data['count']; $i++) {
        $uac = $data[$i]['useraccountcontrol'][0] ?? 0;
        if ($uac & 2) {
            $total_disabled++;
        } else {
            $total_active++;
        }
    }
} while ($cookie !== null && $cookie != '');

echo "TOTAL LDAP USERS: " . ($total_active + $total_disabled) . "
";
echo "LDAP ACTIVE: $total_active
";
echo "LDAP DISABLED: $total_disabled
";
?>
