<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');

CModule::IncludeModule('iblock');

$IBLOCK_ID = 3;

// 1. Identify users to keep
$keep_ids = [1]; // Always keep root
$rsAdmins = $DB->Query("SELECT USER_ID FROM b_user_group WHERE GROUP_ID = 1");
while($a = $rsAdmins->Fetch()) $keep_ids[] = $a['USER_ID'];

$service_patterns = [
    "agroadmin", "vardo001", "bitrix_ad", "sql_", "1c_", 
    "healthmailbox", "sb.", "scan_", "meec", "croptrd",
    "admin", "bot", "support", "engine", "manage", "help",
    "ldapuser", "service", "system", "test", "bitrix", "portal"
];

$rsUsers = CUser::GetList($by="ID", $order="ASC", array());
$deactivated = 0;
while($u = $rsUsers->Fetch()) {
    if(in_array($u['ID'], $keep_ids)) continue;
    if($u['EXTERNAL_AUTH_ID'] == 'bot') continue;
    
    $skip = false;
    foreach($service_patterns as $p) {
        if(str_contains(strtolower($u['LOGIN']), $p) || str_contains(strtolower($u['NAME']), $p) || str_contains(strtolower($u['LAST_NAME']), $p)) {
            $skip = true;
            break;
        }
    }
    
    if(!$skip) {
        $user = new CUser;
        $user->Update($u['ID'], array("ACTIVE" => "N", "UF_DEPARTMENT" => []));
        $deactivated++;
    }
}
echo "Deactivated $deactivated users.\n";

// 2. Delete all departments
echo "Deleting all departments...\n";
$bs = new CIBlockSection;
$rs = CIBlockSection::GetList(array(), array('IBLOCK_ID' => $IBLOCK_ID));
while($s = $rs->Fetch()) {
    $bs->Delete($s['ID']);
}

// 3. Clear HR tables
if ($DB->TableExists("b_hr_structure_node")) {
    echo "Clearing HR structure tables...\n";
    $DB->Query("DELETE FROM b_hr_structure_node");
    $DB->Query("DELETE FROM b_hr_structure_node_member");
}

// 4. Clear caches
echo "Clearing caches...\n";
BXClearCache(true);
$GLOBALS["CACHE_MANAGER"]->CleanAll();

echo "Cleanup complete! System is ready for AD synchronization.\n";
?>
