<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
$res = CUser::GetList(($by="id"), ($order="asc"), [], ['FIELDS' => ['ID', 'LOGIN', 'NAME', 'LAST_NAME', 'SECOND_NAME']]);
$users = [];
while($u = $res->Fetch()) {
    $users[] = $u;
}
echo json_encode($users, JSON_UNESCAPED_UNICODE);
