<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
CModule::IncludeModule('iblock');
function resort_manual($iblock_id) {
    // Bitrix doesn't have a simple ReTree, we update one section to trigger resort
    $res = CIBlockSection::GetList([], ['IBLOCK_ID' => $iblock_id, 'DEPTH_LEVEL' => 1], false, ['ID']);
    if ($s = $res->Fetch()) {
        $bs = new CIBlockSection;
        $bs->Update($s['ID'], ['NAME' => $s['NAME']]); // Update triggers internal resort
        return "Triggered resort on section ".$s['ID'];
    }
    return "No level 1 sections found";
}
echo resort_manual(3);
die();
