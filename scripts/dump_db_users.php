<?php
$mysqli = new mysqli('10.0.1.200', 'bitrix', 'S0m3_Str0ng_Pass!', 'prostory');
if ($mysqli->connect_error) die('Connect Error: ' . $mysqli->connect_error);
$res = $mysqli->query('SELECT ID, LOGIN, NAME, LAST_NAME, SECOND_NAME FROM b_user');
$users = [];
while ($row = $res->fetch_assoc()) {
    $users[] = $row;
}
echo json_encode($users, JSON_UNESCAPED_UNICODE);
