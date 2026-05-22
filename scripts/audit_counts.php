<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');

CModule::IncludeModule('iblock');

$IBLOCK_ID = 3;
$rs = CIBlockSection::GetList([], ["IBLOCK_ID" => $IBLOCK_ID]);
while($sect = $rs->Fetch()) {
    $rsUsers = CUser::GetList($by="ID", $order="ASC", array("UF_DEPARTMENT" => $sect['ID'], "ACTIVE" => "Y"));
    echo "Dept: {$sect['NAME']} (ID: {$sect['ID']}) => Count: " . $rsUsers->SelectedRowsCount() . "\n";
}

$rsGroups = CGroup::GetList($by="ID", $order="ASC");
while($group = $rsGroups->Fetch()) {
    $rsUsers = CUser::GetList($by="ID", $order="ASC", array("GROUPS_ID" => array($group['ID']), "ACTIVE" => "Y"));
    echo "Group: {$group['NAME']} (ID: {$group['ID']}) => Count: " . $rsUsers->SelectedRowsCount() . "\n";
}
?>
