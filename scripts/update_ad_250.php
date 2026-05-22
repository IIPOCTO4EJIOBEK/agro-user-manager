<?php
// update_ad_250.php - Обновление department, manager и деактивация мусора в AD 250
ini_set('memory_limit', '1024M');

$csv_path = __DIR__ . '/production_users.csv';
$ad_server = "ldap://10.0.1.250";
$ad_user = "Administrator@sync.rusagroeco.ru";
$ad_pass = "Admin@2026Prostory!";
$base_dn = "OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru";

$EXCLUDE_COMPANIES = ['Агроконсалтинг', 'АКФ ПромСтройФинанс', 'Конто-М', 'ПК НКС', 'ТД "НКС"', 'Тестовая'];
$EXCLUDE_DEPTS = ['Агроконсалтинг', 'Аппарат президента', 'Техническая запись', 'Техническая учетная запись', 'Тестировщиков', 'Внешние сотрудники'];
$EXCLUDE_LOGINS = ['krbtgt', 'Гость', 'Администратор'];

function isExcluded($login, $company, $dept, $display_name, $enabled) {
    global $EXCLUDE_COMPANIES, $EXCLUDE_DEPTS, $EXCLUDE_LOGINS;
    if ($enabled == 'False') return true;
    if (!$login || strpos($login, '$') === 0) return true;
    $login_lower = strtolower($login);
    foreach (['svc_', 'admin_', 'test_', 'mailbox'] as $ex) {
        if (strpos($login_lower, $ex) !== false) return true;
    }
    if (in_array($login, $EXCLUDE_LOGINS)) return true;
    foreach ($EXCLUDE_COMPANIES as $ex) {
        if (stripos($company, $ex) !== false) return true;
    }
    foreach ($EXCLUDE_DEPTS as $ex) {
        if (stripos($dept, $ex) !== false) return true;
    }
    if (strpos($display_name, 'Microsoft Exchange') !== false || strpos($display_name, 'SystemMailbox') !== false) return true;
    return false;
}

// 1. Читаем CSV и строим маппинги
$old_dn_to_login = [];
$valid_users = []; // login => row
$fh = fopen($csv_path, 'r');
$header = fgetcsv($fh); // Читаем заголовок (с учетом BOM)
$header[0] = preg_replace('/^\xEF\xBB\xBF/', '', $header[0]); // убираем BOM
while (($row = fgetcsv($fh)) !== false) {
    if (count($row) != count($header)) continue;
    $data = array_combine($header, $row);
    $login = $data['SamAccountName'];
    $old_dn = $data['DistinguishedName'];
    
    if ($old_dn && $login) {
        $old_dn_to_login[$old_dn] = strtolower($login);
    }
    
    if (!isExcluded($login, $data['Company'], $data['Department'], $data['DisplayName'], $data['Enabled'])) {
        $valid_users[strtolower($login)] = $data;
    }
}
fclose($fh);

echo "Found " . count($valid_users) . " valid users in CSV.\n";

// 2. Подключаемся к AD 250
$ldap = ldap_connect($ad_server);
ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_set_option($ldap, LDAP_OPT_REFERRALS, 0);
if (!@ldap_bind($ldap, $ad_user, $ad_pass)) {
    die("Cannot connect to AD 250");
}

// 3. Получаем всех пользователей из AD 250 и их новые DN
$ad250_login_to_dn = [];
$cookie = '';
do {
    $controls = [['oid' => LDAP_CONTROL_PAGEDRESULTS, 'value' => ['size' => 1000, 'cookie' => $cookie]]];
    $res = ldap_search($ldap, $base_dn, "(&(objectClass=user)(objectCategory=person))", ['samaccountname'], 0, 0, 0, LDAP_DEREF_NEVER, $controls);
    $entries = ldap_get_entries($ldap, $res);
    for ($i = 0; $i < $entries['count']; $i++) {
        $login = strtolower($entries[$i]['samaccountname'][0]);
        $ad250_login_to_dn[$login] = $entries[$i]['dn'];
    }
    ldap_parse_result($ldap, $res, $err, $mdn, $emsg, $refs, $ctrls);
    $cookie = $ctrls[LDAP_CONTROL_PAGEDRESULTS]['value']['cookie'] ?? '';
} while ($cookie !== '');

echo "Found " . count($ad250_login_to_dn) . " users in AD 250.\n";

// 4. Обновляем данные в AD 250
$updated = 0;
$disabled = 0;

foreach ($ad250_login_to_dn as $login => $dn) {
    if (isset($valid_users[$login])) {
        // Это валидный пользователь, обновляем department и manager
        $user_data = $valid_users[$login];
        $dept = $user_data['Department'] ? $user_data['Department'] : 'Прочее';
        
        // Вычисляем руководителя
        $old_manager_dn = $user_data['Manager'];
        $new_manager_dn = null;
        if ($old_manager_dn && isset($old_dn_to_login[$old_manager_dn])) {
            $mgr_login = $old_dn_to_login[$old_manager_dn];
            if (isset($ad250_login_to_dn[$mgr_login])) {
                $new_manager_dn = $ad250_login_to_dn[$mgr_login];
            }
        }
        
        $mod = [];
        $mod['department'] = $dept;
        if ($new_manager_dn) {
            $mod['manager'] = $new_manager_dn;
        } else {
            // Очищаем руководителя если его нет
            $mod['manager'] = [];
        }
        
        // Делаем modify
        if (@ldap_modify($ldap, $dn, $mod)) {
            $updated++;
        } else {
            // Если manager=[] вызывает ошибку (например поля нет), делаем через mod_replace
            $err = ldap_errno($ldap);
            if ($err) {
                $mod2 = ['department' => $dept];
                @ldap_modify($ldap, $dn, $mod2);
            }
        }
        
        // Убеждаемся что он Enabled
        @ldap_modify($ldap, $dn, ['useraccountcontrol' => 512]); 

    } else {
        // Это мусорный пользователь (Агроконсалтинг, техучетка и тд) - отключаем его
        @ldap_modify($ldap, $dn, ['useraccountcontrol' => 514]); // 514 = Disabled
        $disabled++;
    }
}

echo "AD 250 Update Complete.\n";
echo "Valid users updated: $updated\n";
echo "Garbage users disabled: $disabled\n";
