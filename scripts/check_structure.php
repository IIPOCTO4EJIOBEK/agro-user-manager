<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
if(!CModule::IncludeModule('iblock')) die('No iblock');
if(!CModule::IncludeModule('iblock')) die('No iblock');

global $DB;

// Mapping from final_structure_mapped.json - path to new ID
$newPaths = [];
$res = CIBlockSection::GetList([], ['IBLOCK_ID' => 3], false, ['ID', 'NAME', 'IBLOCK_SECTION_ID']);
while($s = $res->Fetch()) {
    $parentPath = '';
    if($s['IBLOCK_SECTION_ID'] > 0) {
        $parent = CIBlockSection::GetByID($s['IBLOCK_SECTION_ID'])->Fetch();
        if($parent) $parentPath = $parent['NAME'];
    }
    $currentPath = $parentPath ? $parentPath.'/'.$s['NAME'] : $s['NAME'];
    $newPaths[$currentPath] = $s['ID'];
    echo "PATH: $currentPath => ID: {$s['ID']}\n";
}

echo "\n=== Total new sections: ".count($newPaths)." ===\n";

// Now check users
echo "\n=== Sample users with old UF_DEPARTMENT ===\n";
$res = $DB->Query("SELECT u.ID, u.LOGIN, u.LAST_NAME, u.NAME, uts.UF_DEPARTMENT 
    FROM b_user u 
    INNER JOIN b_uts_user uts ON u.ID = uts.USER_ID 
    WHERE uts.UF_DEPARTMENT IS NOT NULL AND uts.UF_DEPARTMENT != 'a:0:{}' 
    LIMIT 30");
while($u = $res->Fetch()) {
    $dept = unserialize($u['UF_DEPARTMENT']);
    echo "User ID:{$u['ID']} ({$u['LAST_NAME']} {$u['NAME']}) => DEPT_IDS: ".json_encode($dept)."\n";
}
?>
