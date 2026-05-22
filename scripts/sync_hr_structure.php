<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
global $DB;

echo "=== Sync HR Structure with IBlock ===\n\n";

// Clear old HR structure nodes
echo "Clearing old HR structure nodes...\n";
$DB->Query("DELETE FROM b_hr_structure_node WHERE STRUCTURE_ID = 1");

// Get all sections from IBlock 3
CModule::IncludeModule('iblock');
$res = CIBlockSection::GetList(
    ['LEFT_MARGIN' => 'ASC'],
    ['IBLOCK_ID' => 3],
    false,
    ['ID', 'NAME', 'IBLOCK_SECTION_ID', 'DEPTH_LEVEL', 'LEFT_MARGIN', 'RIGHT_MARGIN', 'SORT']
);

$sections = [];
while($s = $res->Fetch()) {
    $sections[$s['ID']] = $s;
}

echo "Found ".count($sections)." sections in IBlock\n";

// Build ID mapping: old IBLOCK_SECTION_ID -> new HR node ID
$iblockIdToHrNodeId = [];

// Insert sections in order (by LEFT_MARGIN to maintain hierarchy)
echo "\nCreating HR structure nodes...\n";
$created = 0;
$errors = 0;

foreach($sections as $iblockId => $s) {
    $parentId = 0;
    if($s['IBLOCK_SECTION_ID'] && isset($iblockIdToHrNodeId[$s['IBLOCK_SECTION_ID']])) {
        $parentId = $iblockIdToHrNodeId[$s['IBLOCK_SECTION_ID']];
    }
    
    $name = $DB->ForSql($s['NAME']);
    $sort = intval($s['SORT']);
    
    $sql = "INSERT INTO b_hr_structure_node (STRUCTURE_ID, NAME, PARENT_ID, SORT) 
            VALUES (1, '$name', $parentId, $sort)";
    
    $res = $DB->Query($sql);
    if($res) {
        // Get last insert ID
        $idRes = $DB->Query("SELECT LAST_INSERT_ID() as ID");
        $idRow = $idRes->Fetch();
        $newId = $idRow['ID'];
        $iblockIdToHrNodeId[$iblockId] = $newId;
        $created++;
    } else {
        echo "Error creating node for $s[NAME]: ".$DB->GetErrorMessage()."\n";
        $errors++;
    }
    
    if($created % 20 == 0) {
        echo "Progress: $created created...\n";
    }
}

echo "\n=== Complete ===\n";
echo "Created: $created\n";
echo "Errors: $errors\n";

// Verify
echo "\n=== Verification ===\n";
$r = $DB->Query("SELECT COUNT(*) as C FROM b_hr_structure_node WHERE STRUCTURE_ID = 1")->Fetch();
echo "HR structure nodes: ".$r['C']."\n";

// Show first 15 nodes
echo "\nFirst 15 HR nodes:\n";
$res = $DB->Query("SELECT ID, NAME, PARENT_ID, SORT FROM b_hr_structure_node WHERE STRUCTURE_ID = 1 ORDER BY ID LIMIT 15");
while($n = $res->Fetch()) {
    echo "  HR_ID:$n[ID] PARENT:$n[PARENT_ID] SORT:$n[SORT] - $n[NAME]\n";
}

// Show mapping
echo "\nID Mapping (IBlock -> HR):\n";
$shown = 0;
foreach($iblockIdToHrNodeId as $ibId => $hrId) {
    echo "  IBlock:$ibId -> HR:$hrId\n";
    if(++$shown >= 15) break;
}
?>
