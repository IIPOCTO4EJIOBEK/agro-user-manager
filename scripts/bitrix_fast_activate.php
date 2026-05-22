<?php
define("NO_KEEP_STATISTIC", true);
define("NOT_CHECK_PERMISSIONS", true);
$_SERVER["DOCUMENT_ROOT"] = "/home/bitrix/www";
require_once($_SERVER["DOCUMENT_ROOT"]."/bitrix/modules/main/include/prolog_before.php");

$whiteListPath = __DIR__ . "/white_list_ad.txt";
$adLogins = array_map('trim', file($whiteListPath));
$adLogins = array_map('strtolower', $adLogins);

$userObj = new CUser;
echo "Activating unique users from AD 250 white-list...\n";

$activatedCount = 0;
$processedLogins = [];

foreach ($adLogins as $login) {
    if (isset($processedLogins[$login])) continue;
    
    // Берем самого свежего по ID
    $rsBX = CUser::GetList(($by="ID"), ($order="DESC"), array("LOGIN_EQUAL_EXACT" => $login));
    if ($arBX = $rsBX->Fetch()) {
        $userObj->Update($arBX["ID"], array("ACTIVE" => "Y"));
        $processedLogins[$login] = $arBX["ID"];
        $activatedCount++;
    }
}

$finalCount = 0;
$rsFinal = CUser::GetList(($by="ID"), ($order="ASC"), array("ACTIVE" => "Y"));
while($f = $rsFinal->Fetch()) $finalCount++;

echo "Activated from white-list: $activatedCount\n";
echo "Total Active in Bitrix24 now: $finalCount\n";
?>
