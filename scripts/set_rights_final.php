<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
global $DB;

echo "=== Setting IBlock Rights ===\n\n";

$IBLOCK_ID = 3;

// Clear existing rights
echo "Clearing existing rights...\n";
$DB->Query("DELETE FROM b_iblock_right WHERE IBLOCK_ID = $IBLOCK_ID");

// Get task IDs
echo "Getting task IDs...\n";
$tasks = [];
$res = $DB->Query("SELECT ID, NAME FROM b_task WHERE MODULE_ID = 'iblock'");
while($t = $res->Fetch()) {
    $tasks[$t['NAME']] = $t['ID'];
}

$adminTask = isset($tasks['iblock_full']) ? $tasks['iblock_full'] : 72;
$readTask = isset($tasks['iblock_read']) ? $tasks['iblock_read'] : 66;

echo "Using: admin=$adminTask, read=$readTask\n";

// Insert rights
// GROUP_CODE format: G<GROUP_ID> for groups, R<ROLE_ID> for roles, U<USER_ID> for users
$rights = [
    // Administrators (group 1) - full access
    ['GROUP_CODE' => 'G1', 'TASK_ID' => $adminTask],
    // All authorized users (group 2) - read access
    ['GROUP_CODE' => 'G2', 'TASK_ID' => $readTask],
];

echo "\nSetting rights...\n";
foreach($rights as $r) {
    $sql = "INSERT INTO b_iblock_right (IBLOCK_ID, GROUP_CODE, TASK_ID, DO_INHERIT) 
            VALUES ($IBLOCK_ID, '{$r['GROUP_CODE']}', {$r['TASK_ID']}, 'Y')";
    if($DB->Query($sql)) {
        echo "  Added: Group {$r['GROUP_CODE']} Task {$r['TASK_ID']}\n";
    } else {
        echo "  Error: ".$DB->GetErrorMessage()."\n";
    }
}

// Verify
echo "\n=== Verification ===\n";
$res = $DB->Query("SELECT GROUP_CODE, TASK_ID FROM b_iblock_right WHERE IBLOCK_ID = $IBLOCK_ID");
echo "Rights set:\n";
while($r = $res->Fetch()) {
    echo "  Group: {$r['GROUP_CODE']} Task: {$r['TASK_ID']}\n";
}

// Clear cache
echo "\nClearing cache...\n";
$DB->Query("DELETE FROM b_cache_tag WHERE TAG LIKE '%iblock_right%'");

echo "\n=== Complete ===\n";
?>
