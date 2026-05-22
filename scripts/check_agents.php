<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');

$rs = CAgent::GetList([], ["MODULE_ID" => "ldap"]);
while($a = $rs->Fetch()) {
    echo "Agent: {$a['NAME']} (ID: {$a['ID']}) Next run: {$a['NEXT_EXEC']}\n";
}

$rs = CAgent::GetList([], ["NAME" => "%Sync%"]);
while($a = $rs->Fetch()) {
    echo "Agent: {$a['NAME']} (ID: {$a['ID']}) Next run: {$a['NEXT_EXEC']}\n";
}
?>
