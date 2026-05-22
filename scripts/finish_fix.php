<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');

CModule::IncludeModule('iblock');

$IBLOCK_ID = 3;
$ROOT_NAME = "Агрохолдинг \"ПРОСТОРЫ\"";

// 1. Sync HR structure table with IBlock 3
echo "Syncing HR structure table with IBlock 3...\n";
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

$root_rs = CIBlockSection::GetList([], ["IBLOCK_ID" => $IBLOCK_ID, "NAME" => $ROOT_NAME, "DEPTH_LEVEL" => 1]);
if($root_sect = $root_rs->Fetch()) {
    $hr_root_id = $hrMap[$root_sect['ID']];
    echo "HR Root Node ID: $hr_root_id\n";
    $sql_hr = "INSERT IGNORE INTO b_hr_structure_node_member (ENTITY_TYPE, ENTITY_ID, NODE_ID, ADDED_BY, CREATED_AT, UPDATED_AT)
               SELECT 'USER', ID, $hr_root_id, 1, NOW(), NOW() FROM b_user WHERE ACTIVE='Y'";
    $DB->Query($sql_hr);
}

// 2. Clear Cache
echo "Clearing caches...\n";
BXClearCache(true);
$GLOBALS["CACHE_MANAGER"]->CleanAll();

echo "Done!\n";
?>
