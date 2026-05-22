<?php
/**
 * BITRIX24 BIRTHDAY & GENDER IMPORTER v3.5
 */
ini_set('memory_limit','1024M');
set_time_limit(0);

$CFG = require __DIR__.'/config.php';

function rest($method, $data = []) {
    global $CFG;
    $url = $CFG['webhook'] . $method . '.json';
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    $response = curl_exec($ch);
    curl_close($ch);
    return json_decode($response, true);
}

function convertMonth($m) {
    $map = [
        'января'=>'01', 'февраля'=>'02', 'марта'=>'03', 'апреля'=>'04',
        'мая'=>'05', 'июня'=>'06', 'июля'=>'07', 'августа'=>'08',
        'сентября'=>'09', 'октября'=>'10', 'ноября'=>'11', 'декабря'=>'12'
    ];
    return $map[mb_strtolower($m)] ?? '01';
}

function detectGender($fio) {
    $parts = explode(' ', $fio);
    $sn = mb_strtolower(end($parts));
    if (str_ends_with($sn, 'ич') || str_ends_with($sn, 'ыч')) return 'M';
    if (str_ends_with($sn, 'на')) return 'F';
    return '';
}

// 1. Карта пользователей из БД
$mysqli = new mysqli("10.0.1.200", "bitrix", "S0m3_Str0ng_Pass!", "prostory");
$res = $mysqli->query("SELECT ID, NAME, LAST_NAME, SECOND_NAME FROM b_user WHERE ACTIVE='Y'");
$usersMap = [];
while($u = $res->fetch_assoc()) {
    $full = trim($u['LAST_NAME']." ".$u['NAME']." ".$u['SECOND_NAME']);
    $usersMap[$full] = $u['ID'];
}

// 2. Обработка данных
$lines = file('/tmp/birthday_data.txt');
$updated = 0;

foreach ($lines as $line) {
    $cols = explode("	", trim($line));
    if (count($cols) < 4) continue;
    
    // Ищем ФИО (обычно в 3 или 2 колонке)
    $fio = "";
    foreach($cols as $c) {
        if (count(explode(' ', trim($c))) >= 3) { $fio = trim($c); break; }
    }
    if (empty($fio)) continue;

    // Ищем Дату
    $dateRaw = "";
    foreach($cols as $c) {
        if (preg_match('/(\d+)\s+([а-я]+)/iu', $c, $m)) {
            $day = str_pad($m[1], 2, '0', STR_PAD_LEFT);
            $month = convertMonth($m[2]);
            $dateRaw = "$day.$month.1900"; // Используем 1900 год как заглушку, если год рождения неизвестен
            break;
        }
    }

    if (isset($usersMap[$fio]) && $dateRaw) {
        $gender = detectGender($fio);
        rest('user.update', [
            'ID' => $usersMap[$fio],
            'PERSONAL_BIRTHDAY' => $dateRaw,
            'PERSONAL_GENDER' => $gender
        ]);
        $updated++;
        echo "Updated: $fio ($dateRaw, $gender)
";
    }
}

echo "Total updated: $updated employees.
";
