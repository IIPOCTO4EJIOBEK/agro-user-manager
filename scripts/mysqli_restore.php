<?php
/**
 * Восстановление через MySQLi напрямую
 */

$mysqli = new mysqli('10.0.1.200', 'bitrix', 'S0m3_Str0ng_Pass!', 'prostory');
if($mysqli->connect_error) die('Connect error: '.$mysqli->connect_error);

echo "=== ВОССТАНОВЛЕНИЕ (MySQLi) ===\n\n";

// 1. Очистка
echo "1. Очистка...\n";
$mysqli->query("DELETE FROM b_iblock_section WHERE IBLOCK_ID = 3");
$mysqli->query("DELETE FROM b_uts_iblock_3_section");
$mysqli->query("DELETE FROM b_hr_structure_node WHERE STRUCTURE_ID = 1");
$mysqli->query("DELETE FROM b_hr_structure_node_member");
echo "   OK\n";

// 2. JSON
echo "\n2. Загрузка данных...\n";
$content = file_get_contents('/home/bitrix/www/apply_structure.php');
$start = strpos($content, "\$json = '") + strlen("\$json = '");
$end = strpos($content, "';", $start);
$jsonStr = substr($content, $start, $end - $start);
$flat = json_decode($jsonStr, true);
echo "   Записей: ".count($flat)."\n";

// 3. Отделы
echo "\n3. Создание отделов...\n";
$paths = [];
$created = 0;

foreach($flat as $f) {
    $parentId = isset($f['parent_path']) && isset($paths[$f['parent_path']]) ? $paths[$f['parent_path']] : 0;
    $name = $mysqli->real_escape_string($f['name']);
    $head = $f['head'] ? intval($f['head']) : null;
    
    $sql = "INSERT INTO b_iblock_section (IBLOCK_ID, NAME, IBLOCK_SECTION_ID, SORT, ACTIVE, LEFT_MARGIN, RIGHT_MARGIN, DEPTH_LEVEL)
            VALUES (3, '$name', $parentId, $created, 'Y', 0, 0, ".($parentId > 0 ? 2 : 1).")";
    
    if($mysqli->query($sql)) {
        $newId = $mysqli->insert_id;
        $paths[$f['path']] = $newId;
        
        if($head) {
            $mysqli->query("INSERT INTO b_uts_iblock_3_section (VALUE_ID, UF_HEAD) VALUES ($newId, $head)");
        }
        $created++;
    }
    
    if($created % 20 == 0) echo "   Создано: $created...\n";
}
echo "   Всего: $created\n";

// 4. Nested Set
echo "\n4. Nested Set...\n";
$res = $mysqli->query("SELECT ID, IBLOCK_SECTION_ID FROM b_iblock_section WHERE IBLOCK_ID=3 ORDER BY ID");
$children = [];
while($s = $res->fetch_assoc()) {
    if($s['IBLOCK_SECTION_ID']) {
        if(!isset($children[$s['IBLOCK_SECTION_ID']])) $children[$s['IBLOCK_SECTION_ID']] = [];
        $children[$s['IBLOCK_SECTION_ID']][] = $s['ID'];
    }
}

$counter = 0;
$rebuild = function($id) use (&$rebuild, &$counter, &$children, $mysqli) {
    $counter++;
    $left = $counter;
    if(isset($children[$id])) {
        foreach($children[$id] as $childId) $rebuild($childId);
    }
    $counter++;
    $right = $counter;
    $mysqli->query("UPDATE b_iblock_section SET LEFT_MARGIN=$left, RIGHT_MARGIN=$right WHERE ID=$id");
};

$res = $mysqli->query("SELECT ID FROM b_iblock_section WHERE IBLOCK_ID=3 AND (IBLOCK_SECTION_ID IS NULL OR IBLOCK_SECTION_ID=0)");
while($r = $res->fetch_assoc()) $rebuild($r['ID']);
echo "   Counter: $counter\n";

// 5. HR
echo "\n5. HR-структура...\n";
$res = $mysqli->query("SELECT ID, NAME, IBLOCK_SECTION_ID, SORT FROM b_iblock_section WHERE IBLOCK_ID=3 ORDER BY LEFT_MARGIN");
$iblockToHr = [];
while($s = $res->fetch_assoc()) {
    $parentId = $s['IBLOCK_SECTION_ID'] && isset($iblockToHr[$s['IBLOCK_SECTION_ID']]) ? $iblockToHr[$s['IBLOCK_SECTION_ID']] : 0;
    $name = $mysqli->real_escape_string($s['NAME']);
    $mysqli->query("INSERT INTO b_hr_structure_node (STRUCTURE_ID, NAME, PARENT_ID, SORT) VALUES (1, '$name', $parentId, ".intval($s['SORT']).")");
    $iblockToHr[$s['ID']] = $mysqli->insert_id;
}
echo "   HR-узлов: ".count($iblockToHr)."\n";

// 6. Сотрудники
echo "\n6. Сотрудники...\n";
$res = $mysqli->query("SELECT VALUE_ID, UF_DEPARTMENT FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'");
$membersAdded = 0;
while($u = $res->fetch_assoc()) {
    $depts = @unserialize($u['UF_DEPARTMENT']);
    if(is_array($depts)) {
        foreach($depts as $deptId) {
            if(isset($iblockToHr[$deptId])) {
                $hrNodeId = $iblockToHr[$deptId];
                $userId = $u['VALUE_ID'];
                $check = $mysqli->query("SELECT ID FROM b_hr_structure_node_member WHERE NODE_ID=$hrNodeId AND ENTITY_TYPE='USER' AND ENTITY_ID=$userId");
                if(!$check->fetch_assoc()) {
                    $mysqli->query("INSERT INTO b_hr_structure_node_member (ENTITY_TYPE, ENTITY_ID, NODE_ID, ADDED_BY) VALUES ('USER', $userId, $hrNodeId, 1)");
                    $membersAdded++;
                }
            }
        }
    }
}
echo "   HR-членов: $membersAdded\n";

// 7. Кэш
echo "\n7. Кэш...\n";
$mysqli->query("DELETE FROM b_cache_tag");
$mysqli->query("DELETE FROM b_cache");

echo "\n=== ГОТОВО ===\n";
echo "Отделов: $created\nHR-узлов: ".count($iblockToHr)."\nСотрудников: $membersAdded\n";

$mysqli->close();
?>
