<?php
/**
 * Привязка 29 руководителей к новой структуре
 */
$mysqli = new mysqli('10.0.1.200', 'bitrix', 'S0m3_Str0ng_Pass!', 'prostory');

echo "=== Привязка 29 руководителей ===\n\n";

// Руководители из иерархии (USER_ID => DEPT_NAME)
$managers = [
    9242 => 'Акционерное общество "Агрохолдинг"Просторы"',
    9411 => 'Управление',
    9325 => 'Дирекция по экологической безопасности / ОСП "Ростовское"',
    9487 => 'Дирекция по техническому развитию и инфраструктуре / ОСП "Ростовское"',
    9435 => 'Дирекция по капитальному строительству',
    9531 => 'Центр прикладных генетических и репродуктивных технологий',
    9421 => 'Операционная дирекция / ОСП "Нижегородское"',
    9202 => 'Операционная дирекция / ОСП "Краснодарское"',
    9491 => 'Операционная дирекция / ОСП "Ставропольское"',
    9553 => 'Операционная дирекция / ОСП "Ростовское"',
    9344 => 'Дирекция по агроскаутингу',
    9250 => 'Управление по экономике и финансам',
    9552 => 'Дирекция по казначейским операциям / ОСП "Ростовское"',
    9507 => 'Дирекция по корпоративным финансам',
    9473 => 'Дирекция бухгалтерского учета и отчетности',
    9416 => 'Дирекция финансового контроля и анализа / ОСП "Краснодарское"',
    9320 => 'Финансовая служба / ОСП "Ставропольское"',
    9198 => 'Финансовая служба / ОСП "Краснодарское"',
    8733 => 'Финансовая служба / ОСП "Нижегородское"',
    9378 => 'Управление по корпоративной работе',
    9152 => 'Дирекция по управлению недвижимым имуществом',
    9443 => 'Дирекция правовой и корпоративной работы / ОСП "Ростовское"',
    8781 => 'Управление по корпоративной безопасности / ОСП "Ростовское"',
    9475 => 'Управление по персоналу и организационному развитию',
    9535 => 'Управление научных разработок и цифровизации',
    9108 => 'Дирекция по информационным технологиям',
    9549 => 'Дирекция по стратегии',
    9428 => 'Дирекция по управлению проектами и бизнес-процессами',
    9374 => 'Служба акционерно-инспекторского контроля / ОСП "Ростовское"',
    9160 => 'Дирекция по внутреннему контролю / ОСП "Ростовское"',
    9413 => 'Аппарат генерального директора',
    9478 => 'Управление',
    9479 => 'Дирекция по маркетингу',
    3764 => 'Дирекция по специальным проектам',
];

// Получаем новые ID отделов
$nameToId = [];
$res = $mysqli->query("SELECT ID, NAME FROM b_iblock_section WHERE IBLOCK_ID=3");
while($r = $res->fetch_assoc()) {
    $nameToId[$r['NAME']] = $r['ID'];
}
echo "Отделов в БД: ".count($nameToId)."\n";

// Привязка
$bound = 0;
$notFound = 0;
foreach($managers as $userId => $deptName) {
    if(isset($nameToId[$deptName])) {
        $deptId = $nameToId[$deptName];
        $serialized = serialize([$deptId]);
        $sql = "UPDATE b_uts_user SET UF_DEPARTMENT = '".$mysqli->real_escape_string($serialized)."' WHERE VALUE_ID = $userId";
        if($mysqli->query($sql)) {
            $bound++;
        }
    } else {
        echo "Не найден отдел: $deptName\n";
        $notFound++;
    }
}

echo "\nПривязано руководителей: $bound\n";
echo "Не найдено отделов: $notFound\n";

// HR-структура
echo "\n=== HR-структура ===\n";
$nameToHr = [];
$res = $mysqli->query("SELECT ID, NAME FROM b_hr_structure_node WHERE STRUCTURE_ID=1");
while($r = $res->fetch_assoc()) {
    $nameToHr[$r['NAME']] = $r['ID'];
}

// Привязка к HR-узлам
$hrMembers = 0;
foreach($managers as $userId => $deptName) {
    if(isset($nameToHr[$deptName])) {
        $hrNodeId = $nameToHr[$deptName];
        $check = $mysqli->query("SELECT ID FROM b_hr_structure_node_member WHERE NODE_ID=$hrNodeId AND ENTITY_TYPE='USER' AND ENTITY_ID=$userId");
        if(!$check->fetch_assoc()) {
            $mysqli->query("INSERT INTO b_hr_structure_node_member (ENTITY_TYPE, ENTITY_ID, NODE_ID, ADDED_BY) VALUES ('USER', $userId, $hrNodeId, 1)");
            $hrMembers++;
        }
    }
}
echo "HR-членов добавлено: $hrMembers\n";

$r = $mysqli->query("SELECT COUNT(*) as C FROM b_hr_structure_node_member");
$row = $r->fetch_assoc();
echo "Всего HR-членов: ".$row['C']."\n";

// Итог
$r = $mysqli->query("SELECT COUNT(*) as C FROM b_uts_user WHERE UF_DEPARTMENT != 'a:0:{}'");
$row = $r->fetch_assoc();
echo "\n=== ИТОГО ===\n";
echo "Сотрудников с отделами: ".$row['C']."\n";

$mysqli->close();
?>
