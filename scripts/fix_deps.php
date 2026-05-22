<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
if(!CModule::IncludeModule('iblock')) die('No iblock');

global $DB;

// Read apply_structure.php and extract JSON
$content = file_get_contents('/home/bitrix/www/apply_structure.php');
preg_match("/\\\$json = '(.+?)';/s", $content, $m);
if(!isset($m[1])) die('No JSON found');

$jsonStr = stripslashes($m[1]);
$flat = json_decode($jsonStr, true);
if(!$flat) die('JSON decode failed: '.json_last_error_msg());

echo 'Loaded '.count($flat)." departments\n";

// Build path -> ID
$pathMap = [];
$res = CIBlockSection::GetList([], ['IBLOCK_ID' => 3], false, ['ID', 'NAME', 'IBLOCK_SECTION_ID']);
$sections = [];
while($s = $res->Fetch()) $sections[$s['ID']] = $s;

foreach($sections as $id => $s) {
    $parentPath = '';
    if($s['IBLOCK_SECTION_ID'] > 0 && isset($sections[$s['IBLOCK_SECTION_ID']])) {
        $parent = $sections[$s['IBLOCK_SECTION_ID']];
        $parentPath = $parent['NAME'];
    }
    $currentPath = $parentPath ? $parentPath.'/'.$s['NAME'] : $s['NAME'];
    $pathMap[$currentPath] = $id;
}

echo 'Resolved '.count($pathMap)." paths\n";

// Build user -> depts
$userDepts = [];
foreach($flat as $f) {
    if(isset($pathMap[$f['path']]) && !empty($f['emps'])) {
        $deptId = $pathMap[$f['path']];
        foreach($f['emps'] as $uid) {
            if($uid) {
                if(!isset($userDepts[$uid])) $userDepts[$uid] = [];
                if(!in_array($deptId, $userDepts[$uid])) $userDepts[$uid][] = $deptId;
            }
        }
    }
}

echo 'Users to update: '.count($userDepts)."\n";

// Update
$updated = 0; $errors = 0;
foreach($userDepts as $uid => $deptIds) {
    $ser = serialize($deptIds);
    $uidInt = intval($uid);
    $chk = $DB->Query("SELECT VALUE_ID FROM b_uts_user WHERE VALUE_ID = $uidInt");
    if($chk->Fetch()) {
        $sql = "UPDATE b_uts_user SET UF_DEPARTMENT = '".$DB->ForSql($ser)."' WHERE VALUE_ID = $uidInt";
        if($DB->Query($sql)) $updated++;
        else $errors++;
    } else {
        $sql = "INSERT INTO b_uts_user (VALUE_ID, UF_DEPARTMENT) VALUES ($uidInt, '".$DB->ForSql($ser)."')";
        if($DB->Query($sql)) $updated++;
        else $errors++;
    }
    if($updated % 500 == 0) echo "Progress: $updated...\n";
}

echo "\n=== DONE ===\nUpdated: $updated\nErrors: $errors\n";

// Verify
$r = $DB->Query("SELECT COUNT(*) as C FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'")->Fetch();
echo "Users with UF_DEPARTMENT: ".$r['C']."\n";

// Sample
echo "\nSample users:\n";
$res = $DB->Query("SELECT VALUE_ID, UF_DEPARTMENT FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}' LIMIT 10");
while($u = $res->Fetch()) {
    $d = @unserialize($u['UF_DEPARTMENT']);
    echo "User $u[VALUE_ID] => Depts: ".json_encode($d)."\n";
}

// Check dept IDs exist
echo "\nDepartments in DB:\n";
$res = $DB->Query("SELECT ID, NAME FROM b_iblock_section WHERE IBLOCK_ID=3 LIMIT 10");
while($s = $res->Fetch()) {
    echo "ID: $s[ID] => $s[NAME]\n";
}
?>
