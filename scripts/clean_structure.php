<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
define('BX_CRONTAB', true);
define('BX_NO_ACCELERATOR_RESET', true);

$_SERVER['DOCUMENT_ROOT'] = '/home/bitrix/www';
require($_SERVER['DOCUMENT_ROOT'] . '/bitrix/modules/main/include/prolog_before.php');

if (!CModule::IncludeModule('iblock')) {
    die("IBlock module not found\n");
}

$iblockId = 3;
$bs = new CIBlockSection();

echo "--- DELETING EXCLUDED DEPARTMENTS ---\n";
$res = CIBlockSection::GetList([], [
    'IBLOCK_ID' => $iblockId,
    'XML_ID' => false,
    'NAME' => ['%Агроконсалтинг%', '%Президент%']
], false, ['ID', 'NAME']);

while ($sect = $res->Fetch()) {
    echo "Deleting department: " . $sect['NAME'] . " (ID: " . $sect['ID'] . ")\n";
    if ($bs->Delete($sect['ID'])) {
        echo "[SUCCESS] Deleted $sect[NAME]\n";
    } else {
        echo "[ERROR] Failed to delete $sect[NAME]: " . $bs->LAST_ERROR . "\n";
    }
}

echo "--- DELETING EMPTY MANUAL DEPARTMENTS ---\n";
$res = CIBlockSection::GetList(['LEFT_MARGIN' => 'DESC'], [
    'IBLOCK_ID' => $iblockId,
    'XML_ID' => false
], false, ['ID', 'NAME']);

while ($sect = $res->Fetch()) {
    if ($sect['ID'] == 1) continue;
    
    $childRes = CIBlockSection::GetList([], ['IBLOCK_ID' => $iblockId, 'SECTION_ID' => $sect['ID']], false, ['ID']);
    if (!$childRes->Fetch()) {
        $userRes = CUser::GetList($by, $ord, ['UF_DEPARTMENT' => $sect['ID'], 'ACTIVE' => 'Y']);
        if (!$userRes->Fetch()) {
             echo "Deleting empty manual department: " . $sect['NAME'] . " (ID: " . $sect['ID'] . ")\n";
             if ($bs->Delete($sect['ID'])) {
                 echo "[SUCCESS] Deleted $sect[NAME]\n";
             }
        }
    }
}
