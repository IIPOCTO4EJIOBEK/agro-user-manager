<?php
/**
 * Полное восстановление структуры
 */
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
global $DB;

echo "=== ВОССТАНОВЛЕНИЕ СТРУКТУРЫ ===\n\n";

// 1. Очистка старой структуры
echo "1. Очистка старой структуры...\n";
$DB->Query("DELETE FROM b_iblock_section WHERE IBLOCK_ID = 3");
$DB->Query("DELETE FROM b_uts_iblock_3_section");
echo "   Очистка завершена\n";

// 2. Создание новой структуры из JSON
echo "\n2. Создание отделов...\n";
CModule::IncludeModule('iblock');

$content = file_get_contents('/home/bitrix/www/apply_structure.php');
$start = strpos($content, "\$json = '");
$start += strlen("\$json = '");
$end = strpos($content, "';", $start);
$jsonStr = substr($content, $start, $end - $start);
$flat = json_decode($jsonStr, true);

$bs = new CIBlockSection;
$paths = [];
$created = 0;

foreach($flat as $f) {
    $parentId = 0;
    if($f['parent_path'] && isset($paths[$f['parent_path']])) {
        $parentId = $paths[$f['parent_path']];
    }
    
    $fields = [
        'ACTIVE' => 'Y',
        'IBLOCK_ID' => 3,
        'NAME' => $f['name'],
        'IBLOCK_SECTION_ID' => $parentId,
        'UF_HEAD' => $f['head'] ?: null
    ];
    
    if($id = $bs->Add($fields)) {
        $paths[$f['path']] = $id;
        $created++;
    }
    
    if($created % 20 == 0) echo "   Создано: $created...\n";
}
echo "   Всего создано: $created\n";

// 3. Перестройка Nested Set
echo "\n3. Перестройка иерархии...\n";
$res = CIBlockSection::GetList(['LEFT_MARGIN' => 'ASC'], ['IBLOCK_ID' => 3], false, ['ID', 'IBLOCK_SECTION_ID']);
$sections = [];
$children = [];
while($s = $res->Fetch()) {
    $sections[$s['ID']] = $s;
    if($s['IBLOCK_SECTION_ID']) {
        if(!isset($children[$s['IBLOCK_SECTION_ID']])) $children[$s['IBLOCK_SECTION_ID']] = [];
        $children[$s['IBLOCK_SECTION_ID']][] = $s['ID'];
    }
}

$counter = 0;
$rebuild = function($id) use (&$rebuild, &$counter, &$children, $DB) {
    $counter++;
    $left = $counter;
    if(isset($children[$id])) {
        foreach($children[$id] as $childId) {
            $rebuild($childId);
        }
    }
    $counter++;
    $right = $counter;
    $DB->Query("UPDATE b_iblock_section SET LEFT_MARGIN=$left, RIGHT_MARGIN=$right WHERE ID=$id");
};

$roots = [];
foreach($sections as $id => $s) {
    if(!$s['IBLOCK_SECTION_ID'] || !isset($sections[$s['IBLOCK_SECTION_ID']])) {
        $roots[] = $id;
    }
}
foreach($roots as $rootId) $rebuild($rootId);
echo "   Иерархия перестроена (counter=$counter)\n";

// 4. Синхронизация HR-структуры
echo "\n4. Синхронизация HR-структуры...\n";
$DB->Query("DELETE FROM b_hr_structure_node WHERE STRUCTURE_ID = 1");
$DB->Query("DELETE FROM b_hr_structure_node_member WHERE STRUCTURE_ID = 1");

$res = CIBlockSection::GetList(['LEFT_MARGIN' => 'ASC'], ['IBLOCK_ID' => 3], false, ['ID', 'NAME', 'IBLOCK_SECTION_ID', 'SORT']);
$iblockToHr = [];
while($s = $res->Fetch()) {
    $parentId = 0;
    if($s['IBLOCK_SECTION_ID'] && isset($iblockToHr[$s['IBLOCK_SECTION_ID']])) {
        $parentId = $iblockToHr[$s['IBLOCK_SECTION_ID']];
    }
    $sql = "INSERT INTO b_hr_structure_node (STRUCTURE_ID, NAME, PARENT_ID, SORT) 
            VALUES (1, '".$DB->ForSql($s['NAME'])."', $parentId, ".intval($s['SORT']).")";
    if($DB->Query($sql)) {
        $r = $DB->Query("SELECT LAST_INSERT_ID() as ID");
        $row = $r->Fetch();
        $iblockToHr[$s['ID']] = $row['ID'];
    }
}
echo "   HR-узлов: ".count($iblockToHr)."\n";

// 5. Привязка сотрудников
echo "\n5. Привязка сотрудников...\n";
$res = $DB->Query("SELECT VALUE_ID, UF_DEPARTMENT FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'");
$membersAdded = 0;
while($u = $res->Fetch()) {
    $depts = @unserialize($u['UF_DEPARTMENT']);
    if(is_array($depts)) {
        foreach($depts as $deptId) {
            if(isset($iblockToHr[$deptId])) {
                $hrNodeId = $iblockToHr[$deptId];
                $userId = $u['VALUE_ID'];
                $check = $DB->Query("SELECT ID FROM b_hr_structure_node_member WHERE NODE_ID = $hrNodeId AND ENTITY_TYPE = 'USER' AND ENTITY_ID = $userId");
                if(!$check->Fetch()) {
                    $DB->Query("INSERT INTO b_hr_structure_node_member (ENTITY_TYPE, ENTITY_ID, NODE_ID, ADDED_BY) 
                                VALUES ('USER', $userId, $hrNodeId, 1)");
                    $membersAdded++;
                }
            }
        }
    }
}
echo "   HR-членов: $membersAdded\n";

// 6. Очистка кэша
echo "\n6. Очистка кэша...\n";
$DB->Query("DELETE FROM b_cache_tag");

echo "\n=== ВОССТАНОВЛЕНИЕ ЗАВЕРШЕНО ===\n";
echo "Отделов: $created\n";
echo "HR-узлов: ".count($iblockToHr)."\n";
echo "Сотрудников: $membersAdded\n";
?>
