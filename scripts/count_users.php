<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');

if (!CModule::IncludeModule('iblock')) die("IBlock module not found\n");

$IBLOCK_ID = 3;
$ROOT_NAME = "Агрохолдинг \"ПРОСТОРЫ\"";

$rs = CIBlockSection::GetList([], ["IBLOCK_ID" => $IBLOCK_ID, "NAME" => $ROOT_NAME, "DEPTH_LEVEL" => 1]);
if ($sect = $rs->Fetch()) {
    $root_id = $sect['ID'];
    echo "Root ID: $root_id\n";
    
    // Count users in this department
    $rsUsers = CUser::GetList($by="ID", $order="ASC", array("UF_DEPARTMENT" => $root_id, "ACTIVE" => "Y"));
    echo "Users in Root: " . $rsUsers->SelectedRowsCount() . "\n";
    
    // Total active users
    $rsAll = CUser::GetList($by="ID", $order="ASC", array("ACTIVE" => "Y"));
    echo "Total Active Users: " . $rsAll->SelectedRowsCount() . "\n";
}
?>
