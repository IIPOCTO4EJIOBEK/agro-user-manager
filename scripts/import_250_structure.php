<?php
/**
 * Массовый импорт структуры в Битрикс24
 * Использование: php /home/bitrix/www/import_250_structure.php
 */

define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
if(!CModule::IncludeModule('iblock')) die('No iblock');
if(!CModule::IncludeModule('intranet')) die('No intranet');

global $DB;

echo "=== Массовый импорт структуры (250+ сотрудников) ===\n\n";

// ============================================================================
// ШАГ 1: Загрузка структуры отделов из CSV/JSON
// ============================================================================
echo "ШАГ 1: Загрузка отделов...\n";

// Формат CSV файла (structure.csv):
// ID;NAME;PARENT_ID;UF_HEAD
// 1;Генеральный директор;0;100
// 2;Отдел продаж;1;101
// 3;Отдел маркетинга;1;102

$csvFile = '/home/bitrix/www/structure.csv';
$departments = [];

if(file_exists($csvFile)) {
    echo "Чтение $csvFile...\n";
    $handle = fopen($csvFile, 'r');
    $header = fgetcsv($handle, 1000, ';');
    
    while(($row = fgetcsv($handle, 1000, ';')) !== FALSE) {
        $departments[] = [
            'ID' => $row[0],
            'NAME' => $row[1],
            'PARENT_ID' => $row[2],
            'UF_HEAD' => $row[3]
        ];
    }
    fclose($handle);
    echo "Загружено ".count($departments)." отделов\n";
} else {
    echo "Файл $csvFile не найден. Создаю тестовые данные...\n";
    // Тестовые данные для примера
    for($i = 1; $i <= 250; $i++) {
        $departments[] = [
            'ID' => $i,
            'NAME' => "Отдел #$i",
            'PARENT_ID' => $i > 1 ? 1 : 0,
            'UF_HEAD' => null
        ];
    }
}

// ============================================================================
// ШАГ 2: Создание отделов в IBlock 3
// ============================================================================
echo "\nШАГ 2: Создание отделов в БД...\n";

$iblockId = 3; // ID инфоблока структуры
$oldToNewId = []; // Маппинг старых ID в новые
$bs = new CIBlockSection;

$created = 0;
$errors = 0;

foreach($departments as $dept) {
    $parentId = 0;
    if($dept['PARENT_ID'] && isset($oldToNewId[$dept['PARENT_ID']])) {
        $parentId = $oldToNewId[$dept['PARENT_ID']];
    }
    
    $fields = [
        'ACTIVE' => 'Y',
        'IBLOCK_ID' => $iblockId,
        'NAME' => $dept['NAME'],
        'IBLOCK_SECTION_ID' => $parentId,
        'UF_HEAD' => $dept['UF_HEAD'] ?: null
    ];
    
    if($newId = $bs->Add($fields)) {
        $oldToNewId[$dept['ID']] = $newId;
        $created++;
    } else {
        echo "Ошибка: {$dept['NAME']} - ".$bs->LAST_ERROR."\n";
        $errors++;
    }
    
    if($created % 50 == 0) {
        echo "Прогресс: $created создано...\n";
    }
}

echo "Создано: $created, Ошибок: $errors\n";

// ============================================================================
// ШАГ 3: Перестройка Nested Set (LEFT_MARGIN, RIGHT_MARGIN)
// ============================================================================
echo "\nШАГ 3: Перестройка иерархии...\n";

$res = CIBlockSection::GetList(['LEFT_MARGIN' => 'ASC'], ['IBLOCK_ID' => $iblockId], false, ['ID', 'IBLOCK_SECTION_ID']);
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

// Найти корневые элементы
$roots = [];
foreach($sections as $id => $s) {
    if(!$s['IBLOCK_SECTION_ID'] || !isset($sections[$s['IBLOCK_SECTION_ID']])) {
        $roots[] = $id;
    }
}

foreach($roots as $rootId) {
    $rebuild($rootId);
}

echo "Иерархия перестроена (counter=$counter)\n";

// ============================================================================
// ШАГ 4: Загрузка сотрудников из CSV
// ============================================================================
echo "\nШАГ 4: Привязка сотрудников...\n";

// Формат CSV (users.csv):
// USER_ID;DEPT_IDS;LAST_NAME;NAME;SECOND_NAME
// 100;1,2;Иванов;Иван;Иванович
// 101;3;Петров;Петр;Петрович

$usersFile = '/home/bitrix/www/users.csv';
$users = [];

if(file_exists($usersFile)) {
    echo "Чтение $usersFile...\n";
    $handle = fopen($usersFile, 'r');
    $header = fgetcsv($handle, 1000, ';');
    
    while(($row = fgetcsv($handle, 1000, ';')) !== FALSE) {
        $users[] = [
            'USER_ID' => $row[0],
            'DEPT_IDS' => $row[1], // comma-separated old dept IDs
            'LAST_NAME' => $row[2],
            'NAME' => $row[3],
            'SECOND_NAME' => $row[4]
        ];
    }
    fclose($handle);
    echo "Загружено ".count($users)." сотрудников\n";
} else {
    echo "Файл $usersFile не найден. Пропускаем шаг.\n";
    echo "Для импорта создайте users.csv с форматом:\n";
    echo "USER_ID;DEPT_IDS;LAST_NAME;NAME;SECOND_NAME\n";
}

// Привязка сотрудников к отделам
$assigned = 0;
foreach($users as $user) {
    $oldDeptIds = explode(',', $user['DEPT_IDS']);
    $newDeptIds = [];
    
    foreach($oldDeptIds as $oldId) {
        $oldId = trim($oldId);
        if(isset($oldToNewId[$oldId])) {
            $newDeptIds[] = $oldToNewId[$oldId];
        }
    }
    
    if(!empty($newDeptIds)) {
        $serialized = serialize($newDeptIds);
        $userId = intval($user['USER_ID']);
        
        // Проверяем запись
        $check = $DB->Query("SELECT VALUE_ID FROM b_uts_user WHERE VALUE_ID = $userId");
        if($check->Fetch()) {
            $DB->Query("UPDATE b_uts_user SET UF_DEPARTMENT = '".$DB->ForSql($serialized)."' WHERE VALUE_ID = $userId");
        } else {
            $DB->Query("INSERT INTO b_uts_user (VALUE_ID, UF_DEPARTMENT) VALUES ($userId, '".$DB->ForSql($serialized)."')");
        }
        
        $assigned++;
    }
    
    if($assigned % 50 == 0) {
        echo "Прогресс: $assigned привязано...\n";
    }
}

echo "Привязано: $assigned сотрудников\n";

// ============================================================================
// ШАГ 5: Синхронизация HR-структуры
// ============================================================================
echo "\nШАГ 5: Синхронизация HR-структуры...\n";

// Очистка старой HR-структуры
$DB->Query("DELETE FROM b_hr_structure_node WHERE STRUCTURE_ID = 1");
$DB->Query("DELETE FROM b_hr_structure_node_member WHERE STRUCTURE_ID = 1");

// Создание новых узлов
$res = CIBlockSection::GetList(['LEFT_MARGIN' => 'ASC'], ['IBLOCK_ID' => $iblockId], false, ['ID', 'NAME', 'IBLOCK_SECTION_ID', 'SORT']);
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

echo "HR-узлов создано: ".count($iblockToHr)."\n";

// Привязка членов к HR-узлам
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

echo "HR-членов добавлено: $membersAdded\n";

// ============================================================================
// ШАГ 6: Очистка кэша
// ============================================================================
echo "\nШАГ 6: Очистка кэша...\n";
$DB->Query("DELETE FROM b_cache_tag WHERE TAG LIKE '%iblock%'");
$DB->Query("DELETE FROM b_cache_tag WHERE TAG LIKE '%hr_structure%'");

echo "\n=== ИМПОРТ ЗАВЕРШЁН ===\n";
echo "Отделов создано: $created\n";
echo "Сотрудников привязано: $assigned\n";
echo "HR-членов: $membersAdded\n";
echo "\nОбновите страницу Битрикс24 (Ctrl+F5)\n";
?>
