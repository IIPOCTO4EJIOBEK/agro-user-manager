<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
$_SERVER['DOCUMENT_ROOT'] = '/home/bitrix/www';
require($_SERVER['DOCUMENT_ROOT'] . '/bitrix/modules/main/include/prolog_before.php');

if (!CModule::IncludeModule('iblock')) die('iblock failed');

$iblockId = 3;
$bs = new CIBlockSection();

// Удаляем всё кроме ID=1
$res = CIBlockSection::GetList(['LEFT_MARGIN' => 'DESC'], ['IBLOCK_ID' => $iblockId], false, ['ID', 'NAME']);
while ($sect = $res->Fetch()) {
    if ($sect['ID'] == 1) continue;
    echo "Total Delete: " . $sect['NAME'] . "\n";
    $bs->Delete($sect['ID']);
}
