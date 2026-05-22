<?php
ini_set('memory_limit','1024M');
set_time_limit(0);

$CFG = require __DIR__.'/config.php';
$DRY = true; // СТРОГИЙ ТЕСТОВЫЙ РЕЖИМ

function logMsg($m){ echo "[INFO] $m
"; }
function logErr($m){ echo "[ERROR] $m
"; }

// 1. Подключение к БД для маппинга
$mysqli = new mysqli("10.0.1.200", "bitrix", "S0m3_Str0ng_Pass!", "prostory");
$res = $mysqli->query("SELECT ID, LOGIN, NAME, LAST_NAME, EXTERNAL_AUTH_ID FROM b_user WHERE ACTIVE='Y'");
$bxUsers = [];
while ($row = $res->fetch_assoc()) {
    $bxUsers[strtolower($row['LOGIN'])] = $row;
}

// 2. Подключение к LDAP
$ldap = ldap_connect($CFG['ldap_server']);
ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_bind($ldap, $CFG['ldap_user'], $CFG['ldap_pass']);

// 3. Поиск Ключевых Руководителей
function findUserByLogin($ldap, $login) {
    $res = ldap_search($ldap, "DC=rusagroeco,DC=ru", "(sAMAccountName=$login)", ['displayname', 'title', 'dn']);
    $data = ldap_get_entries($ldap, $res);
    return ($data['count'] > 0) ? $data[0] : null;
}

$ceo = findUserByLogin($ldap, 'dyshlyuk.ba');
$deputy = findUserByLogin($ldap, 'plaskov.aa');

echo "=== ПЛАНИРУЕМАЯ ИЕРАРХИЯ ===
";
echo "1. [ROOT] Агрохолдинг ПРОСТОРЫ (Руководитель: " . ($ceo['displayname'][0] ?? "Дышлюк Б.А.") . ")
";
echo "   |-- 2. [DEPUTY] Первый заместитель (Руководитель: " . ($deputy['displayname'][0] ?? "Пласков А.А.") . ")
";

$clusters = [
    'RND' => 'Ростовский кластер',
    'STV' => 'Ставропольский кластер',
    'KRD' => 'Краснодарский кластер',
    'NIZ' => 'Нижегородский кластер',
    'MSK' => 'Московский офис (ЦО)'
];

foreach ($clusters as $code => $name) {
    echo "   |   |-- 3. [CLUSTER] $name ($code)
";
    
    // Ищем исполнительного директора в этом ОУ
    $base = "OU=$code,DC=rusagroeco,DC=ru";
    $res_dir = @ldap_search($ldap, $base, "(&(objectClass=user)(objectCategory=person)(title=*Исполнительный директор*))", ['displayname']);
    if ($res_dir) {
        $dirs = ldap_get_entries($ldap, $res_dir);
        for ($i=0; $i < $dirs['count']; $i++) {
            echo "   |   |   |-- Руководитель: " . $dirs[$i]['displayname'][0] . "
";
        }
    }
    
    // Ищем локальные предприятия (Солнечное и др.)
    $res_sub = @ldap_list($ldap, $base, "(objectClass=organizationalUnit)", ['ou']);
    if ($res_sub) {
        $subs = ldap_get_entries($ldap, $res_sub);
        for ($i=0; $i < $subs['count']; $i++) {
            $ou_name = $subs[$i]['ou'][0];
            if (in_array($ou_name, ['Users', 'Groups', 'Computers'])) continue;
            if (preg_match('/(Аппарат президента|Агроконсалтинг)/iu', $ou_name)) continue;
            echo "   |   |   |-- [ENTITY] $ou_name
";
        }
    }
}

echo "
=== ОЧИСТКА ===
";
echo "[CLEANUP] Группа 'Аппарат президента' -> БУДЕТ УДАЛЕНА ИЗ СТРУКТУРЫ
";
echo "[CLEANUP] Группа 'Агроконсалтинг' -> БУДЕТ УДАЛЕНА ИЗ СТРУКТУРЫ
";

echo "
[INFO] DRY-RUN COMPLETE. Все связи выстроены на основе AD OUs и полей Title.
";
