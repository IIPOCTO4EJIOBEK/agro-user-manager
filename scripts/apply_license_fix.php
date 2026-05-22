<?php
/**
 * Bitrix24 License Fix / Trial Reset
 * 
 * This script rewrites the license key, removes the hashed admin password option
 * to reset trial-related checks, and clears the managed cache.
 */
define("NO_KEEP_STATISTIC", true);
define("NOT_CHECK_PERMISSIONS", true);
$_SERVER["DOCUMENT_ROOT"] = "/home/bitrix/www";
require_once($_SERVER["DOCUMENT_ROOT"]."/bitrix/modules/main/include/prolog_before.php");

if (!CModule::IncludeModule("main")) die("Main module not found");

$LICENSE_KEY_VALUE = 'P25-ML-PLBNQN7UM28BGK5XQMSI';
$licensePath = $_SERVER["DOCUMENT_ROOT"]."/bitrix/license_key.php";

// 1. Rewrite license_key.php
$content = "<? \$LICENSE_KEY = \"$LICENSE_KEY_VALUE\"; ?>";
if (file_put_contents($licensePath, $content)) {
    echo "SUCCESS: license_key.php rewritten.\n";
} else {
    echo "ERROR: Could not rewrite license_key.php.\n";
}

// 2. Clear admin_passwordh in DB
COption::RemoveOption("main", "admin_passwordh");
echo "SUCCESS: admin_passwordh removed from COption.\n";

// 3. Clear managed_cache
if (class_exists("BXClearCache")) {
    $bxCache = new BXClearCache;
    $bxCache->cleanAll();
    echo "SUCCESS: Cache cleared.\n";
} else {
    echo "BXClearCache not found, trying manual...\n";
}

echo "FINISHED: License fix applied.\n";
?>
