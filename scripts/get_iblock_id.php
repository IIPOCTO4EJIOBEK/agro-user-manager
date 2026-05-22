<?php
$mysqli = new mysqli('10.0.1.200', 'bitrix', 'S0m3_Str0ng_Pass!', 'prostory');
if ($mysqli->connect_error) die('Connect Error');
$res = $mysqli->query("SELECT ID, NAME, CODE FROM b_iblock WHERE (IBLOCK_TYPE_ID = 'intranet' AND CODE = 'departments') OR NAME = 'Подразделения' OR NAME = 'Departments'");
$ib = $res->fetch_assoc();
echo json_encode($ib);
