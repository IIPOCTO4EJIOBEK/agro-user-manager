<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');

$IBLOCK_ID = 3;
$ROOT_ID = 457;

$found = [];
$rsUsers = CUser::GetList($by="ID", $order="ASC", array("UF_DEPARTMENT" => $ROOT_ID, "ACTIVE" => "Y"));
while($u = $rsUsers->Fetch()) $found[] = $u['ID'];

echo "Count from API: " . count($found) . "\n";

global $DB;
$res = $DB->Query("SELECT VALUE_ID FROM b_uts_user WHERE UF_DEPARTMENT = 'a:1:{i:0;i:457;}'");
$sql_ids = [];
while($row = $res->Fetch()) $sql_ids[] = $row['VALUE_ID'];

echo "Count from SQL: " . count($sql_ids) . "\n";

$diff = array_diff($sql_ids, $found);
echo "Difference (first 10): " . implode(', ', array_slice($diff, 0, 10)) . "\n";

// Check first diff user
if(!empty($diff)) {
    $uid = reset($diff);
    $rs = CUser::GetByID($uid);
    $u = $rs->Fetch();
    echo "User #$uid: ACTIVE={$u['ACTIVE']}, NAME={$u['NAME']}\n";
    $rsUts = $DB->Query("SELECT * FROM b_uts_user WHERE VALUE_ID=$uid");
    $uts = $rsUts->Fetch();
    echo "User #$uid UTS Dept: {$uts['UF_DEPARTMENT']}\n";
}
?>
