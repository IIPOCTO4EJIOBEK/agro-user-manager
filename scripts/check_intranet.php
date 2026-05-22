<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');

CModule::IncludeModule('iblock');
CModule::IncludeModule('intranet');

$IBLOCK_ID = 3;
$ROOT_NAME = "Агрохолдинг \"ПРОСТОРЫ\"";

$rs = CIBlockSection::GetList([], ["IBLOCK_ID" => $IBLOCK_ID, "NAME" => $ROOT_NAME, "DEPTH_LEVEL" => 1]);
if ($sect = $rs->Fetch()) {
    $root_id = $sect['ID'];
    echo "Root ID: $root_id\n";
    
    $arEmployees = CIntranetUtils::GetDepartmentEmployees($root_id, true, true, 'Y');
    $count = 0;
    while($e = $arEmployees->Fetch()) $count++;
    echo "Intranet API Employee Count in Root: $count\n";
}
?>
