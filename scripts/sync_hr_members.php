<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
global $DB;

echo "=== Sync HR Structure Members ===\n\n";

// First, build mapping: IBlock ID -> HR Node ID
// We need to read from b_hr_structure_node and match by name/position
CModule::IncludeModule('iblock');

// Get IBlock sections with their HR mapping
$res = CIBlockSection::GetList(['LEFT_MARGIN' => 'ASC'], ['IBLOCK_ID' => 3], false, ['ID', 'NAME', 'LEFT_MARGIN']);
$iblockSections = [];
while($s = $res->Fetch()) {
    $iblockSections[$s['ID']] = $s;
}

// Get HR nodes - we need to match them
// Since we just created them in order, the LEFT_MARGIN order should match HR node ID order
$res = $DB->Query("SELECT ID, NAME, SORT FROM b_hr_structure_node WHERE STRUCTURE_ID = 1 ORDER BY ID");
$hrNodes = [];
$hrNodesByName = [];
while($n = $res->Fetch()) {
    $hrNodes[] = $n;
    $hrNodesByName[$n['NAME']] = $n['ID'];
}

echo "IBlock sections: ".count($iblockSections)."\n";
echo "HR nodes: ".count($hrNodes)."\n";

// Build IBlock ID -> HR Node ID mapping based on creation order
$iblockToHr = [];
$hrIndex = 0;
foreach($iblockSections as $ibId => $s) {
    if($hrIndex < count($hrNodes)) {
        $iblockToHr[$ibId] = $hrNodes[$hrIndex]['ID'];
        $hrIndex++;
    }
}

echo "Mapped: ".count($iblockToHr)." IBlock sections to HR nodes\n";

// Clear old members
echo "\nClearing old HR structure members...\n";
$DB->Query("DELETE FROM b_hr_structure_node_member");

// Get users with UF_DEPARTMENT from b_uts_user
echo "Getting users with departments...\n";
$res = $DB->Query("SELECT VALUE_ID, UF_DEPARTMENT FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'");
$usersToAssign = [];
while($u = $res->Fetch()) {
    $depts = @unserialize($u['UF_DEPARTMENT']);
    if(is_array($depts)) {
        foreach($depts as $deptId) {
            if(isset($iblockToHr[$deptId])) {
                $hrNodeId = $iblockToHr[$deptId];
                if(!isset($usersToAssign[$u['VALUE_ID']])) {
                    $usersToAssign[$u['VALUE_ID']] = [];
                }
                if(!in_array($hrNodeId, $usersToAssign[$u['VALUE_ID']])) {
                    $usersToAssign[$u['VALUE_ID']][$hrNodeId] = true;
                }
            }
        }
    }
}

echo "Users to assign: ".count($usersToAssign)."\n";

// Insert members
$assigned = 0;
$errors = 0;
foreach($usersToAssign as $userId => $hrNodeIds) {
    foreach($hrNodeIds as $hrNodeId => $tmp) {
        // Check if already exists
        $check = $DB->Query("SELECT ID FROM b_hr_structure_node_member WHERE NODE_ID = $hrNodeId AND ENTITY_TYPE = 'USER' AND ENTITY_ID = $userId");
        if($check->Fetch()) continue;
        
        $sql = "INSERT INTO b_hr_structure_node_member (ENTITY_TYPE, ENTITY_ID, NODE_ID, ADDED_BY) VALUES ('USER', $userId, $hrNodeId, 1)";
        if($DB->Query($sql)) {
            $assigned++;
        } else {
            $errors++;
        }
    }
    
    if($assigned % 50 == 0 && $assigned > 0) {
        echo "Progress: $assigned assigned...\n";
    }
}

echo "\n=== Complete ===\n";
echo "Assigned: $assigned\n";
echo "Errors: $errors\n";

// Verify
echo "\n=== Verification ===\n";
$r = $DB->Query("SELECT COUNT(*) as C FROM b_hr_structure_node_member")->Fetch();
echo "HR structure members: ".$r['C']."\n";

// Sample
echo "\nSample members:\n";
$res = $DB->Query("SELECT m.NODE_ID, m.ENTITY_ID as USER_ID, u.LAST_NAME, u.NAME, n.NAME as NODE_NAME 
    FROM b_hr_structure_node_member m 
    JOIN b_user u ON m.ENTITY_ID = u.ID 
    JOIN b_hr_structure_node n ON m.NODE_ID = n.ID 
    LIMIT 15");
while($m = $res->Fetch()) {
    echo "  User $m[USER_ID] ($m[LAST_NAME] $m[NAME]) -> Node $m[NODE_ID] ($m[NODE_NAME])\n";
}
?>
