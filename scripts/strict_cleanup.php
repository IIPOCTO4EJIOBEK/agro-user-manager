<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');

if (!CModule::IncludeModule('iblock')) die("IBlock module not found\n");

$IBLOCK_ID = 3;

// 1. LOAD AD NAMES
$ad_names = [];
if (file_exists('/root/ad250_names_utf8.txt')) {
    $lines = file('/root/ad250_names_utf8.txt', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $ad_names[] = mb_strtolower(trim($line));
    }
} else {
    die("/root/ad250_names_utf8.txt not found\n");
}
$ad_names = array_unique($ad_names);
echo "Loaded " . count($ad_names) . " names from AD 250 list.\n";

// 2. DEFINE EXCLUSIONS
$service_patterns = [
    "agroadmin", "vardo001", "bitrix_ad", "sql_", "1c_", 
    "healthmailbox", "sb.", "scan_", "meec", "croptrd",
    "admin", "bot", "support", "engine", "manage", "help",
    "ldapuser", "service", "system", "test", "bitrix", "portal"
];

// 3. DEACTIVATE USERS
echo "Starting user deactivation...\n";
$rsUsers = CUser::GetList($by="ID", $order="ASC", array()); // Get all users
$deactivated = 0;
$kept = 0;
while ($u = $rsUsers->Fetch()) {
    $uid = $u['ID'];
    $login = mb_strtolower($u['LOGIN']);
    $name = mb_strtolower(trim($u['NAME']));
    $last = mb_strtolower(trim($u['LAST_NAME']));
    $second = mb_strtolower(trim($u['SECOND_NAME']));
    
    $fio_full = trim("$last $name $second");
    $fio_short = trim("$name $last");
    
    $skip = false;
    if ($uid == 1) $skip = true;
    if ($u['ACTIVE'] == 'N') { $kept++; continue; } // Already inactive
    
    foreach ($service_patterns as $p) {
        if (str_contains($login, $p) || str_contains($name, $p) || str_contains($last, $p)) {
            $skip = true;
            break;
        }
    }
    
    if (!$skip) {
        // Try various combinations to match AD
        $possible = [$fio_full, $fio_short, $last, $name];
        foreach ($possible as $pos) {
            if ($pos && in_array($pos, $ad_names)) {
                $skip = true;
                break;
            }
        }
    }
    
    if (!$skip) {
        $user = new CUser;
        $user->Update($uid, array("ACTIVE" => "N"));
        $deactivated++;
    } else {
        $kept++;
    }
}
echo "User cleanup done. Deactivated: $deactivated, Kept: $kept.\n";

// 4. CLEAR STRUCTURE
echo "Cleaning up existing structure...\n";
$bs = new CIBlockSection;
$rs = CIBlockSection::GetList(array(), array('IBLOCK_ID' => $IBLOCK_ID), false, array('ID'));
while ($s = $rs->Fetch()) {
    $bs->Delete($s['ID']);
}

// 5. CREATE NEW STRUCTURE
$departments = [
    "Агрохолдинг \"ПРОСТОРЫ\"" => [
        "Отдел бухгалтерского учета и отчетности",
        "Отдел по персоналу",
        "Механизированный ток",
        "Отделение №1",
        "Отделение №2",
        "Склад запасных частей и материалов",
        "Автомобильный гараж"
    ]
];

$root_id = 0;
foreach ($departments as $root_name => $subs) {
    $fields = ['ACTIVE' => 'Y', 'IBLOCK_ID' => $IBLOCK_ID, 'NAME' => $root_name, 'IBLOCK_SECTION_ID' => 0, 'SORT' => 10];
    $root_id = $bs->Add($fields);
    if ($root_id) {
        foreach ($subs as $sub_name) {
            $bs->Add(['ACTIVE' => 'Y', 'IBLOCK_ID' => $IBLOCK_ID, 'NAME' => $sub_name, 'IBLOCK_SECTION_ID' => $root_id, 'SORT' => 100]);
        }
    }
}

// 6. ASSIGN ACTIVE USERS TO ROOT
$rsActive = CUser::GetList($by="ID", $order="ASC", array("ACTIVE" => "Y"));
while ($u = $rsActive->Fetch()) {
    $user = new CUser;
    $user->Update($u['ID'], array("UF_DEPARTMENT" => array($root_id)));
}

// 7. HR SYNC
if ($DB->TableExists("b_hr_structure_node")) {
    $DB->Query("DELETE FROM b_hr_structure_node WHERE STRUCTURE_ID = 1");
    $DB->Query("DELETE FROM b_hr_structure_node_member");
    $hrMap = [];
    $res = CIBlockSection::GetList(['LEFT_MARGIN' => 'ASC'], ['IBLOCK_ID' => $IBLOCK_ID]);
    while($s = $res->Fetch()) {
        $pid = ($s['IBLOCK_SECTION_ID'] > 0 && isset($hrMap[$s['IBLOCK_SECTION_ID']])) ? $hrMap[$s['IBLOCK_SECTION_ID']] : 0;
        $sql = "INSERT INTO b_hr_structure_node (NAME, TYPE, STRUCTURE_ID, PARENT_ID, CREATED_BY, CREATED_AT, UPDATED_AT, ACTIVE, GLOBAL_ACTIVE, SORT)
                VALUES ('".$DB->ForSql($s["NAME"])."', 'DEPARTMENT', 1, $pid, 1, NOW(), NOW(), 'Y', 'Y', 500)";
        $DB->Query($sql);
        $hrMap[$s['ID']] = $DB->LastID();
    }
    $res = $DB->Query("SELECT VALUE_ID, UF_DEPARTMENT FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL");
    while($u_row = $res->Fetch()) {
        $depts = @unserialize($u_row["UF_DEPARTMENT"]);
        if(is_array($depts)) {
            foreach($depts as $did) {
                if(isset($hrMap[$did])) {
                    $DB->Query("INSERT IGNORE INTO b_hr_structure_node_member (ENTITY_TYPE, ENTITY_ID, NODE_ID, ADDED_BY, CREATED_AT, UPDATED_AT)
                                VALUES ('USER', ".intval($u_row["VALUE_ID"]).", ".intval($hrMap[$did]).", 1, NOW(), NOW())");
                }
            }
        }
    }
}
echo "Full cleanup and rebuild complete!\n";
?>
