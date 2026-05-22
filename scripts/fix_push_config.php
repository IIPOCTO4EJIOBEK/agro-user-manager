<?php
// /root/B24_Cluster_Project/scripts/fix_push_config.php
// Скрипт перенастройки модуля Push & Pull на работу с HAProxy/Node.js
define("NO_KEEP_STATISTIC", true);
define("NOT_CHECK_PERMISSIONS", true);
$_SERVER["DOCUMENT_ROOT"] = "/home/bitrix/www";
require_once($_SERVER["DOCUMENT_ROOT"]."/bitrix/modules/main/include/prolog_before.php");

if (!CModule::IncludeModule("pull")) die("Pull module not found");

echo "Configuring Push & Pull...\n";

// Код-подпись с сервера 10.0.1.230
$signatureKey = "azTw0fWfYZeOU4JrzXu3UTXtcrWZePoRuAnYCNn9oKRwQIfLqmOYvqRVfJ9s1lZyj5B1L9AWDlFKgpQgX7xEa1MzEUkrkg8suA4qcQVl7UnvJwHoibkhSyvHho6kOGuE";

COption::SetOptionString("pull", "server_enabled", "Y");
COption::SetOptionString("pull", "signature_key", $signatureKey);
COption::SetOptionString("pull", "signature_algo", "sha1");

// Пути согласно настройкам Nginx/HAProxy (Websocket и Pub)
COption::SetOptionString("pull", "path_to_publish", "http://10.0.1.230:8895/bitrix/pub/");
COption::SetOptionString("pull", "path_to_subscribe", "https://b24.ahprostory.ru/bitrix/sub/");
COption::SetOptionString("pull", "path_to_subscribe_websocket", "wss://b24.ahprostory.ru/bitrix/subws/");

COption::SetOptionString("pull", "server_mode", "sharded");

CAgent::RemoveModuleAgents("pull");
CAgent::AddAgent("CPullOptions::ClearCheckMessages();", "pull", "N", 86400);

echo "Push & Pull configuration updated.\n";
?>
