<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
if(!CModule::IncludeModule('iblock')) die('No iblock');

echo "=== Rebuilding Nested Set for IBlock 3 ===\n\n";

// Use CIBlockSection::restoreDepth to fix the tree
// Or manually recalculate using CIBlockSection::GetList and Update

$bs = new CIBlockSection;

// Get all sections sorted by LEFT_MARGIN
$res = CIBlockSection::GetList(
    ['LEFT_MARGIN' => 'ASC'], 
    ['IBLOCK_ID' => 3], 
    false, 
    ['ID', 'NAME', 'IBLOCK_SECTION_ID', 'LEFT_MARGIN', 'RIGHT_MARGIN', 'DEPTH_LEVEL']
);

$sections = [];
while($s = $res->Fetch()) {
    $sections[$s['ID']] = $s;
}

echo "Found ".count($sections)." sections\n";

// Build tree
$tree = [];
$children = [];
foreach($sections as $id => $s) {
    $parentId = $s['IBLOCK_SECTION_ID'];
    if(!$parentId || $parentId == $id) {
        $tree[] = $id;
    }
    if($parentId) {
        if(!isset($children[$parentId])) $children[$parentId] = [];
        $children[$parentId][] = $id;
    }
}

echo "Root sections: ".count($tree)."\n";

// Recursive function to rebuild margins
$counter = 0;
$rebuildErrors = 0;

$rebuild = function($id) use (&$rebuild, &$counter, &$children, &$sections, $bs, &$rebuildErrors) {
    $counter++;
    $left = $counter;
    
    // Process children first
    if(isset($children[$id])) {
        foreach($children[$id] as $childId) {
            $rebuild($childId);
        }
    }
    
    $counter++;
    $right = $counter;
    
    // Update this section
    $fields = [
        'LEFT_MARGIN' => $left,
        'RIGHT_MARGIN' => $right,
    ];
    
    if(!$bs->Update($id, $fields)) {
        echo "Error updating section $id: ".$bs->LAST_ERROR."\n";
        $rebuildErrors++;
    }
};

echo "\nRebuilding margins...\n";
foreach($tree as $rootId) {
    $rebuild($rootId);
}

echo "Counter final: $counter\n";
echo "Rebuild errors: $rebuildErrors\n";

// Verify
echo "\n=== Verification ===\n";
$res = CIBlockSection::GetList(['LEFT_MARGIN' => 'ASC'], ['IBLOCK_ID' => 3], false, ['ID', 'NAME', 'LEFT_MARGIN', 'RIGHT_MARGIN', 'DEPTH_LEVEL']);
echo "First 15 sections after rebuild:\n";
while($s = $res->Fetch()) {
    echo "  ID:$s[ID] L:$s[LEFT_MARGIN] R:$s[RIGHT_MARGIN] D:$s[DEPTH_LEVEL] - $s[NAME]\n";
}

// Check root
$res = CIBlockSection::GetList([], ['IBLOCK_ID' => 3, 'LEFT_MARGIN' => 1], false, ['ID', 'NAME', 'RIGHT_MARGIN']);
if($root = $res->Fetch()) {
    echo "\nRoot section: ID:$root[ID] NAME:$root[NAME] RIGHT_MARGIN:$root[RIGHT_MARGIN]\n";
    echo "Expected RIGHT_MARGIN for 61 sections: ".(61*2)."\n";
}
?>
