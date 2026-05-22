<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');

if (!CModule::IncludeModule('main')) die("Main module not found\n");

echo "Re-indexing all users...\n";
$rsUsers = CUser::GetList($by="ID", $order="ASC", array("ACTIVE" => "Y"));
while($u = $rsUsers->Fetch()) {
    \Bitrix\Main\UserTable::indexRecord($u['ID']);
}
echo "Done!\n";
?>
