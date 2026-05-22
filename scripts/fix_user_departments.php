<?php
/**
 * Fix UF_DEPARTMENT for all users
 * Uses the embedded JSON from apply_structure.php
 */

define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
if(!CModule::IncludeModule('iblock')) die('No iblock');

global $DB;

// Extract JSON from apply_structure.php
$content = file_get_contents('/home/bitrix/www/apply_structure.php');
if(!preg_match("/\\\$json = '(.+?)';/s", $content, $matches)) {
    die("ERROR: Could not extract JSON from apply_structure.php\n");
}

$jsonStr = stripslashes($matches[1]);
$flat = json_decode($jsonStr, true);

if(!$flat) {
    die("ERROR: Could not decode JSON\n");
}

echo "Loaded ".count($flat)." department entries\n";

// Build path -> ID mapping from actual DB
echo "\n=== Building path -> ID mapping ===\n";
$res = CIBlockSection::GetList([], ['IBLOCK_ID' => 3], false, ['ID', 'NAME', 'IBLOCK_SECTION_ID']);
$sections = [];
while($s = $res->Fetch()) {
    $sections[$s['ID']] = $s;
}

$pathMap = [];
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

// Build user_id -> [dept_ids] from the flat structure
$paths = [];
$userDepts = [];

foreach($flat as $f) {
    $parentPath = $f['parent_path'];
    $currentPath = $f['path'];
    
    // Resolve parent ID
    $parentId = 0;
    if($parentPath && isset($pathMap[$parentPath])) {
        $parentId = $pathMap[$parentPath];
    }
    
    // Store current path ID
    if(isset($pathMap[$currentPath])) {
        $paths[$currentPath] = $pathMap[$currentPath];
        
        // Add employees to this department
        if(!empty($f['emps'])) {
            $deptId = $pathMap[$currentPath];
            foreach($f['emps'] as $uid) {
                if($uid) {
                    if(!isset($userDepts[$uid])) $userDepts[$uid] = [];
                    if(!in_array($deptId, $userDepts[$uid])) {
                        $userDepts[$uid][] = $deptId;
                    }
                }
            }
        }
    }
}

echo "Users to update: ".count($userDepts)."\n";

// Update UF_DEPARTMENT in b_uts_user
echo "\n=== Updating UF_DEPARTMENT ===\n";
$updated = 0;
$errors = 0;
$skipped = 0;

foreach($userDepts as $uid => $deptIds) {
    $serialized = serialize($deptIds);
    $uidInt = intval($uid);
    
    // Check if record exists
    $checkRes = $DB->Query("SELECT VALUE_ID FROM b_uts_user WHERE VALUE_ID = $uidInt");
    if($checkRes->Fetch()) {
        // Update existing
        $sql = "UPDATE b_uts_user SET UF_DEPARTMENT = '".$DB->ForSql($serialized)."' WHERE VALUE_ID = $uidInt";
        if($DB->Query($sql)) {
            $updated++;
        } else {
            $errors++;
        }
    } else {
        // Insert new
        $sql = "INSERT INTO b_uts_user (VALUE_ID, UF_DEPARTMENT) VALUES ($uidInt, '".$DB->ForSql($serialized)."')";
        if($DB->Query($sql)) {
            $updated++;
        } else {
            $errors++;
        }
    }
    
    if($updated % 500 == 0) {
        echo "Progress: $updated updated, $errors errors, $skipped skipped\n";
        flush();
    }
}

echo "\n=== COMPLETE ===\n";
echo "Updated: $updated\n";
echo "Errors: $errors\n";

// Verify
echo "\n=== Verification ===\n";
$res = $DB->Query("SELECT COUNT(*) as C FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'");
$r = $res->Fetch();
echo "Users with UF_DEPARTMENT: ".$r['C']."\n";

// Sample
echo "\nSample users after update:\n";
$res = $DB->Query("SELECT VALUE_ID, UF_DEPARTMENT FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}' LIMIT 15");
while($u = $res->Fetch()) {
    $dept = @unserialize($u['UF_DEPARTMENT']);
    echo "User $u[VALUE_ID] => Depts: ".json_encode($dept)."\n";
}

// Check if new dept IDs exist
echo "\n=== Checking if department IDs exist ===\n";
$res = $DB->Query("SELECT ID, NAME FROM b_iblock_section WHERE IBLOCK_ID=3 LIMIT 10");
while($s = $res->Fetch()) {
    echo "Dept ID: $s[ID] => $s[NAME]\n";
}
?>
