<?php
/**
 * Восстановление структуры без prolog_before
 */
require_once('/home/bitrix/www/bitrix/php_interface/dbconn.php');
require_once('/home/bitrix/www/bitrix/modules/main/include/mysql_database.php');

$DB = new CDatabase();
$DB->Connect($DBHost, $DBName, $DBLogin, $DBPassword);

echo "=== ВОССТАНОВЛЕНИЕ СТРУКТУРЫ (Direct DB) ===\n\n";

// 1. Очистка
echo "1. Очистка...\n";
$DB->Query("DELETE FROM b_iblock_section WHERE IBLOCK_ID = 3");
$DB->Query("DELETE FROM b_uts_iblock_3_section");
$DB->Query("DELETE FROM b_hr_structure_node WHERE STRUCTURE_ID = 1");
$DB->Query("DELETE FROM b_hr_structure_node_member");
echo "   OK\n";

// 2. Загрузка JSON
echo "\n2. Загрузка данных...\n";
$content = file_get_contents('/home/bitrix/www/apply_structure.php');
$start = strpos($content, "\$json = '") + strlen("\$json = '");
$end = strpos($content, "';", $start);
$jsonStr = substr($content, $start, $end - $start);
$flat = json_decode($jsonStr, true);
echo "   Загружено: ".count($flat)." записей\n";

// 3. Создание отделов
echo "\n3. Создание отделов...\n";
$paths = [];
$created = 0;

foreach($flat as $f) {
    $parentId = isset($f['parent_path']) && isset($paths[$f['parent_path']]) ? $paths[$f['parent_path']] : 0;
    $name = $DB->ForSql($f['name']);
    $head = $f['head'] ? intval($f['head']) : 'NULL';
    $sort = intval($f['head'] ? $created : 0);
    
    $sql = "INSERT INTO b_iblock_section (IBLOCK_ID, NAME, IBLOCK_SECTION_ID, SORT, ACTIVE, LEFT_MARGIN, RIGHT_MARGIN, DEPTH_LEVEL)
            VALUES (3, '$name', $parentId, $sort, 'Y', 0, 0, ".($parentId > 0 ? 2 : 1).")";
    
    if($DB->Query($sql)) {
        $r = $DB->Query("SELECT LAST_INSERT_ID() as ID");
        $row = $r->Fetch();
        $newId = $row['ID'];
        $paths[$f['path']] = $newId;
        
        // UF_HEAD
        if($f['head']) {
            $DB->Query("INSERT INTO b_uts_iblock_3_section (VALUE_ID, UF_HEAD) VALUES ($newId, ".intval($f['head']).")");
        }
        
        $created++;
    }
    
    if($created % 20 == 0) echo "   Создано: $created...\n";
}
echo "   Всего: $created\n";

// 4. Перестройка Nested Set
echo "\n4. Перестройка иерархии...\n";
$res = $DB->Query("SELECT ID, IBLOCK_SECTION_ID FROM b_iblock_section WHERE IBLOCK_ID=3 ORDER BY ID");
$children = [];
while($s = $res->Fetch()) {
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
        foreach($children[$id] as $childId) $rebuild($childId);
    }
    $counter++;
    $right = $counter;
    $DB->Query("UPDATE b_iblock_section SET LEFT_MARGIN=$left, RIGHT_MARGIN=$right WHERE ID=$id");
};

$res = $DB->Query("SELECT ID FROM b_iblock_section WHERE IBLOCK_ID=3 AND (IBLOCK_SECTION_ID IS NULL OR IBLOCK_SECTION_ID=0)");
while($r = $res->Fetch()) $rebuild($r['ID']);

echo "   Counter: $counter\n";

// 5. HR-структура
echo "\n5. HR-структура...\n";
$res = $DB->Query("SELECT ID, NAME, IBLOCK_SECTION_ID, SORT FROM b_iblock_section WHERE IBLOCK_ID=3 ORDER BY LEFT_MARGIN");
$iblockToHr = [];
while($s = $res->Fetch()) {
    $parentId = $s['IBLOCK_SECTION_ID'] && isset($iblockToHr[$s['IBLOCK_SECTION_ID']]) ? $iblockToHr[$s['IBLOCK_SECTION_ID']] : 0;
    $name = $DB->ForSql($s['NAME']);
    $DB->Query("INSERT INTO b_hr_structure_node (STRUCTURE_ID, NAME, PARENT_ID, SORT) VALUES (1, '$name', $parentId, ".intval($s['SORT']).")");
    $r = $DB->Query("SELECT LAST_INSERT_ID() as ID");
    $row = $r->Fetch();
    $iblockToHr[$s['ID']] = $row['ID'];
}
echo "   HR-узлов: ".count($iblockToHr)."\n";

// 6. Сотрудники
echo "\n6. Сотрудники...\n";
$res = $DB->Query("SELECT VALUE_ID, UF_DEPARTMENT FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'");
$membersAdded = 0;
while($u = $res->Fetch()) {
    $depts = @unserialize($u['UF_DEPARTMENT']);
    if(is_array($depts)) {
        foreach($depts as $deptId) {
            if(isset($iblockToHr[$deptId])) {
                $hrNodeId = $iblockToHr[$deptId];
                $userId = $u['VALUE_ID'];
                $check = $DB->Query("SELECT ID FROM b_hr_structure_node_member WHERE NODE_ID=$hrNodeId AND ENTITY_TYPE='USER' AND ENTITY_ID=$userId");
                if(!$check->Fetch()) {
                    $DB->Query("INSERT INTO b_hr_structure_node_member (ENTITY_TYPE, ENTITY_ID, NODE_ID, ADDED_BY) VALUES ('USER', $userId, $hrNodeId, 1)");
                    $membersAdded++;
                }
            }
        }
    }
}
echo "   HR-членов: $membersAdded\n";

// 7. Кэш
echo "\n7. Очистка кэша...\n";
$DB->Query("DELETE FROM b_cache_tag");
$DB->Query("DELETE FROM b_cache");

echo "\n=== ГОТОВО ===\n";
echo "Отделов: $created\nHR-узлов: ".count($iblockToHr)."\nСотрудников: $membersAdded\n";
?>
