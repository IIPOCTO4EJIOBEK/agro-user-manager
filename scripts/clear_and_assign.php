<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
if(!CModule::IncludeModule('iblock')) die('No iblock');

global $DB;

echo "=== STEP 1: Clear ALL UF_DEPARTMENT ===\n";

// Count before
$r = $DB->Query("SELECT COUNT(*) as C FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'")->Fetch();
$before = $r['C'];
echo "Users with UF_DEPARTMENT before: $before\n";

// Clear all UF_DEPARTMENT
$res = $DB->Query("UPDATE b_uts_user SET UF_DEPARTMENT = 'a:0:{}' WHERE UF_DEPARTMENT IS NOT NULL");
if($res) {
    echo "UF_DEPARTMENT cleared successfully\n";
} else {
    echo "Error clearing: ".$DB->GetErrorMessage()."\n";
}

echo "\n=== STEP 2: Re-assign managers from hierarchy ===\n";

// Extract JSON from apply_structure.php
$content = file_get_contents('/home/bitrix/www/apply_structure.php');
$start = strpos($content, "\$json = '");
if($start === false) die("Start not found\n");
$start += strlen("\$json = '");
$end = strpos($content, "';", $start);
if($end === false) die("End not found\n");
$jsonStr = substr($content, $start, $end - $start);

$flat = json_decode($jsonStr, true);
if(!$flat) die("Decode error: ".json_last_error_msg()."\n");

// Build path -> ID mapping
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

echo "Resolved ".count($pathMap)." department paths\n";

// Build user -> departments (only heads and employees from hierarchy)
$userDepts = [];
$assignedUsers = 0;
foreach($flat as $f) {
    if(isset($pathMap[$f['path']]) && !empty($f['emps'])) {
        $deptId = $pathMap[$f['path']];
        foreach($f['emps'] as $uid) {
            if($uid) {
                if(!isset($userDepts[$uid])) {
                    $userDepts[$uid] = [];
                    $assignedUsers++;
                }
                if(!in_array($deptId, $userDepts[$uid])) {
                    $userDepts[$uid][] = $deptId;
                }
            }
        }
    }
}

echo "Users to assign: $assignedUsers\n";

// Update UF_DEPARTMENT for managers
$updated = 0; $errors = 0;
foreach($userDepts as $uid => $deptIds) {
    $ser = serialize($deptIds);
    $uidInt = intval($uid);
    
    $sql = "UPDATE b_uts_user SET UF_DEPARTMENT = '".$DB->ForSql($ser)."' WHERE VALUE_ID = $uidInt";
    if($DB->Query($sql)) {
        $updated++;
    } else {
        $errors++;
    }
    
    if($updated % 50 == 0) echo "Progress: $updated...\n";
}

echo "\n=== COMPLETE ===\n";
echo "Cleared: $before\n";
echo "Assigned: $updated\n";
echo "Errors: $errors\n";

// Verify
echo "\n=== Verification ===\n";
$r = $DB->Query("SELECT COUNT(*) as C FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'")->Fetch();
echo "Users with UF_DEPARTMENT: ".$r['C']."\n";

// Sample
echo "\nSample users with departments:\n";
$res = $DB->Query("SELECT VALUE_ID, UF_DEPARTMENT FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}' LIMIT 20");
while($u = $res->Fetch()) {
    $d = @unserialize($u['UF_DEPARTMENT']);
    echo "User $u[VALUE_ID] => Depts: ".json_encode($d)."\n";
}

// Check department IDs exist
echo "\nDepartments in DB:\n";
$res = $DB->Query("SELECT COUNT(*) as C FROM b_iblock_section WHERE IBLOCK_ID=3")->Fetch();
echo "Total departments: ".$r['C']."\n";
?>
