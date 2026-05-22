<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
CModule::IncludeModule('iblock');

echo "=== Structure Check ===\n";
$res = CIBlockSection::GetList(
    ['SORT' => 'ASC', 'NAME' => 'ASC'],
    ['IBLOCK_ID' => 3],
    false,
    ['ID', 'NAME', 'IBLOCK_SECTION_ID', 'DEPTH_LEVEL']
);
$count = 0;
while($s = $res->Fetch()) {
    $indent = str_repeat('  ', $s['DEPTH_LEVEL']-1);
    echo "{$indent}ID:{$s['ID']} - {$s['NAME']}\n";
    $count++;
}
echo "\nTotal: $count sections\n";

// Check users
global $DB;
$r = $DB->Query("SELECT COUNT(*) as C FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'")->Fetch();
echo "Users with departments: ".$r['C']."\n";

$r = $DB->Query("SELECT COUNT(*) as C FROM b_user")->Fetch();
echo "Total users: ".$r['C']."\n";
?>
