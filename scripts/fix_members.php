<?php
/**
 * Привязка сотрудников к новой структуре
 */
$mysqli = new mysqli('10.0.1.200', 'bitrix', 'S0m3_Str0ng_Pass!', 'prostory');

echo "=== Привязка сотрудников ===\n\n";

// Старые названия -> Новые ID
$oldNamesToNewIds = [];
$res = $mysqli->query("SELECT ID, NAME FROM b_iblock_section WHERE IBLOCK_ID=3");
while($r = $res->fetch_assoc()) {
    $oldNamesToNewIds[$r['NAME']] = $r['ID'];
}
echo "Отделов в новой структуре: ".count($oldNamesToNewIds)."\n";

// HR узлы
$hrNodes = [];
$res = $mysqli->query("SELECT ID, NAME FROM b_hr_structure_node WHERE STRUCTURE_ID=1");
while($r = $res->fetch_assoc()) {
    $hrNodes[$r['NAME']] = $r['ID'];
}
echo "HR-узлов: ".count($hrNodes)."\n";

// Сопоставление старых и новых ID через названия
$oldDeptData = [];
$res = $mysqli->query("SELECT ID, NAME FROM b_iblock_section WHERE IBLOCK_ID=3");
while($r = $res->fetch_assoc()) {
    $oldDeptData[$r['ID']] = $r['NAME'];
}

// Получаем пользователей со старыми UF_DEPARTMENT
$res = $mysqli->query("SELECT VALUE_ID, UF_DEPARTMENT FROM b_uts_user WHERE UF_DEPARTMENT IS NOT NULL AND UF_DEPARTMENT != 'a:0:{}'");
$usersToFix = [];
while($u = $res->fetch_assoc()) {
    $depts = @unserialize($u['UF_DEPARTMENT']);
    if(is_array($depts)) {
        $usersToFix[$u['VALUE_ID']] = $depts;
    }
}
echo "Пользователей для привязки: ".count($usersToFix)."\n";

// Привязка
$membersAdded = 0;
foreach($usersToFix as $userId => $oldDeptIds) {
    $newHrNodes = [];
    
    foreach($oldDeptIds as $oldDeptId) {
        // Находим название старого отдела
        if(isset($oldDeptData[$oldDeptId])) {
            $deptName = $oldDeptData[$oldDeptId];
            // Находим HR-узел по названию
            if(isset($hrNodes[$deptName])) {
                $newHrNodes[] = $hrNodes[$deptName];
            }
        }
    }
    
    // Добавляем в HR-структуру
    foreach(array_unique($newHrNodes) as $hrNodeId) {
        $check = $mysqli->query("SELECT ID FROM b_hr_structure_node_member WHERE NODE_ID=$hrNodeId AND ENTITY_TYPE='USER' AND ENTITY_ID=$userId");
        if(!$check->fetch_assoc()) {
            $mysqli->query("INSERT INTO b_hr_structure_node_member (ENTITY_TYPE, ENTITY_ID, NODE_ID, ADDED_BY) VALUES ('USER', $userId, $hrNodeId, 1)");
            $membersAdded++;
        }
    }
    
    if($membersAdded % 100 == 0 && $membersAdded > 0) {
        echo "   Привязано: $membersAdded...\n";
    }
}

echo "\n=== ГОТОВО ===\n";
echo "HR-членов добавлено: $membersAdded\n";

// Итог
$r = $mysqli->query("SELECT COUNT(*) as C FROM b_hr_structure_node_member");
$row = $r->fetch_assoc();
echo "Всего HR-членов: ".$row['C']."\n";

$mysqli->close();
?>
