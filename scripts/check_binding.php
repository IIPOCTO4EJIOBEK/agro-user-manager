<?php
define('NOT_CHECK_PERMISSIONS', true);
require('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');

echo "=== Module Check ===\n";
if(CModule::IncludeModule('intranet')) {
    echo "Intranet module: loaded\n";
} else {
    echo "Intranet module: NOT loaded\n";
}

if(CModule::IncludeModule('iblock')) {
    echo "Iblock module: loaded\n";
    
    // Check iblock 3
    $res = CIBlock::GetList([], ['ID' => 3]);
    if($ib = $res->Fetch()) {
        echo "IBlock 3: TYPE=$ib[IBLOCK_TYPE_ID], CODE=$ib[CODE], ACTIVE=$ib[ACTIVE]\n";
    }
    
    // Check for structure type
    $res = CIBlock::GetList([], ['TYPE' => 'structure']);
    echo "\nStructure-type iblocks:\n";
    while($ib = $res->Fetch()) {
        echo "  ID:$ib[ID] TYPE:$ib[IBLOCK_TYPE_ID] CODE:$ib[CODE]\n";
    }
}

// Check user field UF_DEPARTMENT binding
if(CModule::IncludeModule('main')) {
    echo "\n=== User Field UF_DEPARTMENT ===\n";
    $res = CUserTypeEntity::GetList([], ['FIELD_NAME' => 'UF_DEPARTMENT']);
    if($uf = $res->Fetch()) {
        echo "UF_DEPARTMENT found:\n";
        print_r($uf);
    } else {
        echo "UF_DEPARTMENT NOT found in CUserTypeEntity\n";
    }
}
?>
