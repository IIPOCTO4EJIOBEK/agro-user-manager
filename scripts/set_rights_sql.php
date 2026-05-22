<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
global $DB;

echo "=== Setting IBlock Rights via SQL ===\n\n";

$IBLOCK_ID = 3;

// Clear existing rights
echo "Clearing existing rights...\n";
$DB->Query("DELETE FROM b_iblock_right WHERE IBLOCK_ID = $IBLOCK_ID");

// Insert default rights
// Role IDs: 1=Administrators, 2=All authorized users, 5=Employees
// Task IDs from b_task: need to find appropriate ones

// First, get task IDs
echo "Getting task IDs...\n";
$tasks = [];
$res = $DB->Query("SELECT ID, NAME, MODULE_ID FROM b_task WHERE MODULE_ID = 'iblock'");
while($t = $res->Fetch()) {
    $tasks[$t['NAME']] = $t['ID'];
    echo "  Task: {$t['NAME']} ID: {$t['ID']}\n";
}

// Use appropriate task IDs
$adminTask = isset($tasks['iblock_admin']) ? $tasks['iblock_admin'] : 1;
$readTask = isset($tasks['iblock_read']) ? $tasks['iblock_read'] : 2;
$fullTask = isset($tasks['iblock_full']) ? $tasks['iblock_full'] : 3;

echo "\nUsing tasks: admin=$adminTask, read=$readTask, full=$fullTask\n";

// Insert rights for different groups
$rights = [
    // Administrators (group 1) - full access
    ['GROUP_ID' => 1, 'TASK_ID' => $adminTask, 'RIGHTS_TYPE' => 'G'],
    // All authorized users (group 2) - read access
    ['GROUP_ID' => 2, 'TASK_ID' => $readTask, 'RIGHTS_TYPE' => 'G'],
];

echo "\nSetting rights...\n";
foreach($rights as $r) {
    $sql = "INSERT INTO b_iblock_right (IBLOCK_ID, GROUP_ID, TASK_ID, RIGHTS_TYPE, RIGHTS_MODE) 
            VALUES ($IBLOCK_ID, {$r['GROUP_ID']}, {$r['TASK_ID']}, '{$r['RIGHTS_TYPE']}', 'D')";
    if($DB->Query($sql)) {
        echo "  Added: Group {$r['GROUP_ID']} Task {$r['TASK_ID']} Type {$r['RIGHTS_TYPE']}\n";
    } else {
        echo "  Error: ".$DB->GetErrorMessage()."\n";
    }
}

// Verify
echo "\n=== Verification ===\n";
$res = $DB->Query("SELECT GROUP_ID, TASK_ID, RIGHTS_TYPE FROM b_iblock_right WHERE IBLOCK_ID = $IBLOCK_ID");
echo "Rights set:\n";
while($r = $res->Fetch()) {
    echo "  Group: {$r['GROUP_ID']} Task: {$r['TASK_ID']} Type: {$r['RIGHTS_TYPE']}\n";
}

// Also set rights for all sections
echo "\n=== Setting Section Rights ===\n";
$res = $DB->Query("SELECT ID FROM b_iblock_section WHERE IBLOCK_ID = $IBLOCK_ID");
$sectionCount = 0;
while($s = $res->Fetch()) {
    $sectionId = $s['ID'];
    // Copy rights from iblock level
    $DB->Query("INSERT INTO b_iblock_section_right (IBLOCK_SECTION_ID, GROUP_ID, TASK_ID, RIGHTS_TYPE, RIGHTS_MODE)
                SELECT $sectionId, GROUP_ID, TASK_ID, RIGHTS_TYPE, 'D' 
                FROM b_iblock_right 
                WHERE IBLOCK_ID = $IBLOCK_ID");
    $sectionCount++;
}
echo "Section rights set for $sectionCount sections\n";

// Clear cache
echo "\nClearing cache...\n";
$DB->Query("DELETE FROM b_cache WHERE TAG LIKE '%iblock%'");
$DB->Query("DELETE FROM b_cache_tag WHERE TAG LIKE '%iblock%'");

echo "\n=== Complete ===\n";
echo "Please log out and log in again, then try accessing structure\n";
?>
