<?php
/**
 * sync_hierarchy_final.php
 * Оптимизированная синхронизация 1725 человек.
 */
define("NO_KEEP_STATISTIC", true);
define("NOT_CHECK_PERMISSIONS", true);
$_SERVER["DOCUMENT_ROOT"] = "/home/bitrix/www";
require_once($_SERVER["DOCUMENT_ROOT"]."/bitrix/modules/main/include/prolog_before.php");

if (!CModule::IncludeModule("main", "iblock")) die("Modules not found");

// 1. Карта Логин -> ID
$rsUsers = CUser::GetList(($by="ID"), ($order="ASC"), array("ACTIVE" => "Y"), array("FIELDS" => array("ID", "LOGIN")));
$loginToId = [];
while($arUser = $rsUsers->Fetch()) $loginToId[strtolower($arUser["LOGIN"])] = $arUser["ID"];

// 2. Карта Название отдела -> ID
$deptIblockId = 3; // Мы уже знаем, что ID=3
$rsDepts = CIBlockSection::GetList([], ["IBLOCK_ID" => $deptIblockId], false, ["ID", "NAME"]);
$nameToDeptId = [];
while($arDept = $rsDepts->Fetch()) $nameToDeptId[trim($arDept["NAME"])] = $arDept["ID"];

// 3. AD 250 (Идеальная структура)
$ldap = ldap_connect("ldap://10.0.1.250");
ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_bind($ldap, "Administrator@sync.rusagroeco.ru", "Admin@2026Prostory!");

$base_dn = "OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru";
$search = ldap_search($ldap, $base_dn, "(&(objectClass=user)(objectCategory=person))", ['samaccountname', 'department', 'manager', 'title']);
$entries = ldap_get_entries($ldap, $search);

$userObj = new CUser;
$section = new CIBlockSection;
$total = $entries['count'];
$updated = 0;

echo "Total in AD 250: $total. Starting sync...\n";

for ($i=0; $i < $total; $i++) {
    $login = strtolower($entries[$i]['samaccountname'][0]);
    $deptName = $entries[$i]['department'][0] ?? '';
    $title = $entries[$i]['title'][0] ?? '';
    $managerDn = $entries[$i]['manager'][0] ?? '';
    
    if (!isset($loginToId[$login])) continue;
    $userId = $loginToId[$login];
    
    // А) Привязка к отделу и должности
    $fields = ["WORK_POSITION" => $title];
    if (isset($nameToDeptId[$deptName])) {
        $fields["UF_DEPARTMENT"] = [$nameToDeptId[$deptName]];
    }
    
    $userObj->Update($userId, $fields);
    
    // Б) Руководитель подразделения (если есть)
    if ($managerDn && isset($nameToDeptId[$deptName])) {
        preg_match('/CN=([^,]+)/', $managerDn, $matches);
        if ($matches[1]) {
            $rsM = CUser::GetList($b, $o, ["NAME" => $matches[1]], ["FIELDS" => ["ID"]]);
            if ($arM = $rsM->Fetch()) {
                $section->Update($nameToDeptId[$deptName], ["UF_HEAD" => $arM["ID"]]);
            }
        }
    }

    $updated++;
    if ($updated % 100 == 0) echo "Processed $updated / $total...\n";
}

echo "Final Sync Complete! Total updated: $updated.\n";
?>
