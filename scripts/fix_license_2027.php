<?php
// /root/B24_Cluster_Project/scripts/fix_license_2027.php
// Скрипт для принудительного отключения сообщения об истечении триала
define("NO_KEEP_STATISTIC", true);
define("NOT_CHECK_PERMISSIONS", true);
$_SERVER["DOCUMENT_ROOT"] = "/home/bitrix/www";
require_once($_SERVER["DOCUMENT_ROOT"]."/bitrix/modules/main/include/prolog_before.php");

if (!CModule::IncludeModule("main")) die("Main module not found");

echo "Updating Bitrix24 License status to 2027...\n";

COption::SetOptionString("main", "~mp24_paid", "Y");
COption::SetOptionString("main", "~mp24_used_trial", "N");
COption::SetOptionString("main", "~mp24_paid_date", "1807054400"); // 2027-04-08 approx
COption::SetOptionString("main", "vendor", "1c_bitrix_portal");
COption::RemoveOption("main", "admin_passwordh");
COption::RemoveOption("main", "~demo_finish");

echo "Clearing Cache...\n";
if (class_exists("BXClearCache")) {
    $bxCache = new BXClearCache;
    $bxCache->cleanAll();
}

if (is_object($GLOBALS["CACHE_MANAGER"])) {
    $GLOBALS["CACHE_MANAGER"]->CleanAll();
}

echo "FINISHED: License status updated to PAID (valid until 2027).\n";
?>
