<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');

if (!CModule::IncludeModule('iblock')) die("IBlock module not found\n");

$IBLOCK_ID = 3;
$ROOT_NAME = "Агрохолдинг \"ПРОСТОРЫ\"";

// 1. Get the root department ID
$rs = CIBlockSection::GetList([], ["IBLOCK_ID" => $IBLOCK_ID, "NAME" => $ROOT_NAME, "DEPTH_LEVEL" => 1]);
if ($sect = $rs->Fetch()) {
    $root_id = $sect['ID'];
    echo "Found root department: $ROOT_NAME (ID: $root_id)\n";
} else {
    die("Root department not found! Please check IBlock 3 sections.\n");
}

// 2. Get the corresponding HR node ID
$hr_root_id = 0;
if ($DB->TableExists("b_hr_structure_node")) {
    $rs_hr = $DB->Query("SELECT ID FROM b_hr_structure_node WHERE NAME = '".$DB->ForSql($ROOT_NAME)."' AND STRUCTURE_ID = 1 LIMIT 1");
    if ($hr_node = $rs_hr->Fetch()) {
        $hr_root_id = $hr_node['ID'];
        echo "Found HR root node (ID: $hr_root_id)\n";
    }
}

// 3. Update all active users to be in root department
// Using direct SQL for speed as there are 2000+ users
echo "Updating b_uts_user for all active users...\n";
$serialized_dept = serialize(array($root_id));
$sql = "UPDATE b_uts_user uts 
        INNER JOIN b_user u ON uts.VALUE_ID = u.ID 
        SET uts.UF_DEPARTMENT = '".$DB->ForSql($serialized_dept)."' 
        WHERE u.ACTIVE = 'Y'";
$DB->Query($sql);

// Also handle users who might not have an entry in b_uts_user yet
$sql_missing = "INSERT IGNORE INTO b_uts_user (VALUE_ID, UF_DEPARTMENT) 
                SELECT ID, '".$DB->ForSql($serialized_dept)."' FROM b_user WHERE ACTIVE='Y'";
$DB->Query($sql_missing);

// 4. Update HR structure members
if ($hr_root_id > 0) {
    echo "Cleaning and re-populating b_hr_structure_node_member...\n";
    $DB->Query("DELETE FROM b_hr_structure_node_member");
    
    $sql_hr = "INSERT IGNORE INTO b_hr_structure_node_member (ENTITY_TYPE, ENTITY_ID, NODE_ID, ADDED_BY, CREATED_AT, UPDATED_AT)
               SELECT 'USER', ID, $hr_root_id, 1, NOW(), NOW() FROM b_user WHERE ACTIVE='Y'";
    $DB->Query($sql_hr);
}

// 5. Clear Caches
echo "Clearing caches...\n";
BXClearCache(true);
$GLOBALS["CACHE_MANAGER"]->CleanAll();
if (class_exists("\Bitrix\Main\Data\StaticHtmlCache")) {
    \Bitrix\Main\Data\StaticHtmlCache::getInstance()->deleteAll();
}

echo "Done! All active users should now be visible in the structure root.\n";
?>
