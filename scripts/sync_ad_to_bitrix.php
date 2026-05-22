<?php
/**
 * sync_ad_to_bitrix.php
 * Синхронизирует иерархию отделов и привязку пользователей из AD 250 в Битрикс24
 */

define("NO_KEEP_STATISTIC", true);
define("NOT_CHECK_PERMISSIONS", true);
$_SERVER["DOCUMENT_ROOT"] = "/home/bitrix/www";
require_once($_SERVER["DOCUMENT_ROOT"]."/bitrix/modules/main/include/prolog_before.php");

if (!CModule::IncludeModule("main") || !CModule::IncludeModule("iblock")) {
    die("Error: Modules main or iblock not found.\n");
}

global $DB;
$IBLOCK_ID = 3; 
$ROOT_DEPT_ID = 388; // АО Агрохолдинг Просторы

echo "=== STARTING AD TO BITRIX SYNC ===\n";

// 1. Получаем всех активных пользователей из Bitrix (Login -> ID)
$rsUsers = CUser::GetList($b, $o, ["ACTIVE" => "Y"], ["FIELDS" => ["ID", "LOGIN"]]);
$loginToId = [];
while ($u = $rsUsers->Fetch()) {
    $loginToId[strtolower($u["LOGIN"])] = $u["ID"];
}
echo "Loaded " . count($loginToId) . " active users from Bitrix.\n";

// 2. Получаем всех пользователей из AD 250
$ldap = ldap_connect("ldap://10.0.1.250");
ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_set_option($ldap, LDAP_OPT_REFERRALS, 0);
ldap_bind($ldap, "Administrator@sync.rusagroeco.ru", "Admin@2026Prostory!");

$adUsers = [];
$cookie = "";
do {
    $controls = [["oid" => LDAP_CONTROL_PAGEDRESULTS, "value" => ["size" => 1000, "cookie" => $cookie]]];
    $search = ldap_search($ldap, "DC=sync,DC=rusagroeco,DC=ru", "(&(objectClass=user)(objectCategory=person)(department=*))", ["samaccountname", "department", "title"], 0, 0, 0, LDAP_DEREF_NEVER, $controls);
    ldap_parse_result($ldap, $search, $errcode, $matcheddn, $errmsg, $referrals, $serverctrls);
    $cookie = $serverctrls[LDAP_CONTROL_PAGEDRESULTS]["value"]["cookie"] ?? "";
    $entries = ldap_get_entries($ldap, $search);
    for ($i = 0; $i < $entries["count"]; $i++) {
        $login = strtolower($entries[$i]["samaccountname"][0]);
        $adUsers[$login] = [
            "dept" => trim($entries[$i]["department"][0]),
            "title" => $entries[$i]["title"][0] ?? ""
        ];
    }
} while ($cookie !== "" && $cookie !== null);
echo "Loaded " . count($adUsers) . " users from AD.\n";

// 3. Загружаем текущие отделы
$rsDepts = CIBlockSection::GetList([], ["IBLOCK_ID" => $IBLOCK_ID], false, ["ID", "NAME", "IBLOCK_SECTION_ID"]);
$nameToId = [];
while ($d = $rsDepts->Fetch()) {
    $nameToId[trim($d["NAME"])] = $d["ID"];
}

$bs = new CIBlockSection;
function getOrCreateDept($fullName, $IBLOCK_ID, $ROOT_ID, &$nameToId, $bs) {
    $parts = explode("/", $fullName);
    $parentId = $ROOT_ID;
    
    foreach ($parts as $part) {
        $part = trim($part);
        if (empty($part)) continue;
        
        if (isset($nameToId[$part])) {
            $parentId = $nameToId[$part];
            continue;
        }

        $fields = [
            "ACTIVE" => "Y",
            "IBLOCK_ID" => $IBLOCK_ID,
            "NAME" => $part,
            "IBLOCK_SECTION_ID" => $parentId,
            "SORT" => 500
        ];
        $newId = $bs->Add($fields);
        if ($newId) {
            echo "  Created: $part\n";
            $nameToId[$part] = $newId;
            $parentId = $newId;
        } else {
            $parentId = $ROOT_ID;
        }
    }
    return $parentId;
}

// 4. Привязка
$userDeptMap = [];
$deptHeads = [];
$keywords = ["Директор", "Director", "Manager", "Руководитель", "Начальник", "Head"];

foreach ($adUsers as $login => $data) {
    if (!isset($loginToId[$login])) continue;
    $userId = $loginToId[$login];
    $deptId = getOrCreateDept($data["dept"], $IBLOCK_ID, $ROOT_DEPT_ID, $nameToId, $bs);
    
    $userDeptMap[$userId] = [$deptId];
    $isHead = false;
    foreach($keywords as $kw) if(mb_stripos($data["title"], $kw) !== false) { $isHead = true; break; }
    if($isHead && !isset($deptHeads[$deptId])) $deptHeads[$deptId] = $userId;
}

echo "Updating Bitrix users...\n";
$user = new CUser;
foreach ($userDeptMap as $uid => $depts) $user->Update($uid, ["UF_DEPARTMENT" => $depts]);
foreach ($deptHeads as $did => $hid) $bs->Update($did, ["UF_HEAD" => $hid]);

// 5. HR Module Sync
if ($DB->TableExists("b_hr_structure_node")) {
    echo "Syncing b_hr_structure_node...\n";
    $DB->Query("DELETE FROM b_hr_structure_node WHERE STRUCTURE_ID = 1");
    // Удаляем из b_hr_structure_node_member без STRUCTURE_ID
    $DB->Query("DELETE FROM b_hr_structure_node_member"); 
    
    $hrMap = [];
    $rs = CIBlockSection::GetList(["LEFT_MARGIN"=>"ASC"], ["IBLOCK_ID"=>$IBLOCK_ID]);
    while($s = $rs->Fetch()) {
        $pid = ($s["IBLOCK_SECTION_ID"] > 0 && isset($hrMap[$s["IBLOCK_SECTION_ID"]])) ? $hrMap[$s["IBLOCK_SECTION_ID"]] : "NULL";
        $sql = "INSERT INTO b_hr_structure_node (NAME, TYPE, STRUCTURE_ID, PARENT_ID, CREATED_BY, CREATED_AT, UPDATED_AT, ACTIVE, GLOBAL_ACTIVE, SORT)
                VALUES ('".$DB->ForSql($s["NAME"])."', 'DEPARTMENT', 1, $pid, 1, NOW(), NOW(), 'Y', 'Y', ".intval($s["SORT"]).")";
        if($DB->Query($sql)) $hrMap[$s["ID"]] = $DB->LastID();
    }
    
    $res = $DB->Query("SELECT VALUE_ID, UF_DEPARTMENT FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL");
    while($u = $res->Fetch()) {
        $depts = @unserialize($u["UF_DEPARTMENT"]);
        if(is_array($depts)) foreach($depts as $did) if(isset($hrMap[$did])) {
            $DB->Query("INSERT IGNORE INTO b_hr_structure_node_member (ENTITY_TYPE, ENTITY_ID, NODE_ID, ADDED_BY, CREATED_AT, UPDATED_AT)
                        VALUES ('USER', ".intval($u["VALUE_ID"]).", ".$hrMap[$did].", 1, NOW(), NOW())");
        }
    }
}

CIBlockSection::Resort($IBLOCK_ID);
echo "=== SYNC COMPLETE ===\n";
