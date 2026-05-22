<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
if(!CModule::IncludeModule('iblock')) die('No iblock');

echo "=== Setting IBlock Rights ===\n\n";

$IBLOCK_ID = 3;

// Check if rights exist
$iblockRights = new CIBlockRights;
$res = $iblockRights->GetList([], ['IBLOCK_ID' => $IBLOCK_ID]);
$existingRights = [];
while($r = $res->Fetch()) {
    $existingRights[] = $r;
}

echo "Existing rights: ".count($existingRights)."\n";

if(count($existingRights) > 0) {
    echo "Clearing existing rights...\n";
    CIBlockRights::DeleteRights($IBLOCK_ID);
}

// Set new rights
$rights = [
    // Administrators - full access
    [
        'GROUP_ID' => 1,  // Administrators
        'TASK_ID' => 'iblock_admin',  // Full access
        'RIGHTS_TYPE' => 'G'  // Group
    ],
    // All authenticated users - read access to structure
    [
        'GROUP_ID' => 2,  // All authorized users
        'TASK_ID' => 'iblock_read',  // Read only
        'RIGHTS_TYPE' => 'G'
    ],
    // Employees - read access
    [
        'GROUP_ID' => 5,  // Employees (if exists)
        'TASK_ID' => 'iblock_read',
        'RIGHTS_TYPE' => 'G'
    ],
];

echo "Setting new rights...\n";
$iblockRights->SetRights($IBLOCK_ID, $rights);

// Verify
$res = $iblockRights->GetList([], ['IBLOCK_ID' => $IBLOCK_ID]);
$newRights = [];
while($r = $res->Fetch()) {
    $newRights[] = $r;
}

echo "New rights count: ".count($newRights)."\n";
foreach($newRights as $r) {
    echo "  Group/Role: {$r['GROUP_ID']} Task: {$r['TASK_ID']} Type: {$r['RIGHTS_TYPE']}\n";
}

// Also check section-level rights
echo "\n=== Section Rights ===\n";
$sectionRightsObj = new CIBlockSectionRights;
$res = $sectionRightsObj->GetList([], ['IBLOCK_ID' => $IBLOCK_ID]);
$sectionRights = [];
while($r = $res->Fetch()) {
    $sectionRights[] = $r;
}
echo "Section-level rights: ".count($sectionRights)."\n";

// Clear cache
echo "\nClearing cache...\n";
$CACHE = new CCache();
$CACHE->CleanDir('iblock_rights');

echo "\n=== Complete ===\n";
echo "Try accessing structure again in Bitrix24\n";
?>
