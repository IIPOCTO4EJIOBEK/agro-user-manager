<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
CModule::IncludeModule('iblock');
CModule::IncludeModule('intranet');

echo "=== Bitrix24 Structure Check ===\n\n";

// Check via CIBlockSection
$res = CIBlockSection::GetList(
    ['SORT' => 'ASC'],
    ['IBLOCK_ID' => 3],
    false,
    ['ID', 'NAME', 'IBLOCK_SECTION_ID', 'DEPTH_LEVEL', 'LEFT_MARGIN', 'RIGHT_MARGIN']
);

$sections = [];
while($s = $res->Fetch()) {
    $sections[] = $s;
}

echo "Total sections: ".count($sections)."\n\n";

// Show tree
function showTree($sections, $parentId = null, $level = 0) {
    $indent = str_repeat('  ', $level);
    foreach($sections as $s) {
        if($s['IBLOCK_SECTION_ID'] == $parentId) {
            echo "{$indent}ID:{$s['ID']} (L{$s['DEPTH_LEVEL']}) - {$s['NAME']}\n";
            showTree($sections, $s['ID'], $level + 1);
        }
    }
}

echo "Structure tree:\n";
showTree($sections, null, 0);

// Check users with departments
global $DB;
echo "\n=== Users ===\n";
$r = $DB->Query("SELECT COUNT(*) as C FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'")->Fetch();
echo "Users with UF_DEPARTMENT: ".$r['C']."\n";

$r = $DB->Query("SELECT COUNT(*) as C FROM b_user")->Fetch();
echo "Total users: ".$r['C']."\n";

// Sample users
echo "\nSample users with departments:\n";
$res = $DB->Query("SELECT u.ID, u.LOGIN, u.LAST_NAME, u.NAME, uts.UF_DEPARTMENT 
    FROM b_user u 
    INNER JOIN b_uts_user uts ON u.ID = uts.VALUE_ID 
    WHERE uts.UF_DEPARTMENT IS NOT NULL AND uts.UF_DEPARTMENT != 'a:0:{}' 
    LIMIT 10");
while($u = $res->Fetch()) {
    $depts = @unserialize($u['UF_DEPARTMENT']);
    echo "  $u[LAST_NAME] $u[NAME] (ID:$u[ID]) => Depts: ".json_encode($depts)."\n";
}
?>
