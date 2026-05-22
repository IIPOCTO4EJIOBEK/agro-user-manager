<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
CModule::IncludeModule('iblock');

echo "=== FINAL STATE ===\n\n";

// Departments
$res = CIBlockSection::GetList([], ['IBLOCK_ID' => 3], false, ['ID', 'NAME', 'IBLOCK_SECTION_ID', 'UF_HEAD']);
$deptCount = 0;
while($s = $res->Fetch()) $deptCount++;
echo "Departments (IBLOCK_ID=3): $deptCount\n\n";

// Top level departments
echo "Top-level departments:\n";
$res = CIBlockSection::GetList([], ['IBLOCK_ID' => 3, 'IBLOCK_SECTION_ID' => 0], false, ['ID', 'NAME', 'UF_HEAD']);
while($s = $res->Fetch()) {
    echo "  ID:$s[ID] - $s[NAME] (Head: $s[UF_HEAD])\n";
}

// Users with departments
global $DB;
$r = $DB->Query("SELECT COUNT(*) as C FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'")->Fetch();
echo "\nUsers with UF_DEPARTMENT: ".$r['C']."\n";

// Total users
$r = $DB->Query("SELECT COUNT(*) as C FROM b_user")->Fetch();
echo "Total users: ".$r['C']."\n";

// Sample users
echo "\nSample users with departments:\n";
$res = $DB->Query("SELECT u.ID, u.LAST_NAME, u.NAME, uts.UF_DEPARTMENT FROM b_user u JOIN b_uts_user uts ON u.ID = uts.VALUE_ID WHERE uts.UF_DEPARTMENT IS NOT NULL AND uts.UF_DEPARTMENT != 'a:0:{}' LIMIT 15");
while($u = $res->Fetch()) {
    $d = @unserialize($u['UF_DEPARTMENT']);
    echo "  $u[LAST_NAME] $u[NAME] (ID:$u[ID]) => Depts: ".json_encode($d)."\n";
}
?>
