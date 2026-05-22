<?php
define("BX_CRONTAB_SUPPORT", true);
$_SERVER["HTTPS"] = "on";
$_SERVER["SERVER_PORT"] = 443;
$_SERVER["SERVER_NAME"] = "b24.ahprostory.ru";
$_SERVER["HTTP_HOST"] = "b24.ahprostory.ru";

$DBHost = "10.0.1.200";
$DBLogin = "bitrix";
$DBPassword = "S0m3_Str0ng_Pass!";
$DBName = "prostory";
$DBType = "mysql";

define("BX_CACHE_TYPE", "redis");
define("BX_REDIS_HOST", "10.0.1.210");
define("BX_REDIS_PORT", 6379);
define("BX_REDIS_PASSWORD", "B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!");

define("BX_FILE_PERMISSIONS", 0664);
define("BX_DIR_PERMISSIONS", 0775);
@umask(~(BX_FILE_PERMISSIONS | BX_DIR_PERMISSIONS) & 0777);
@ini_set("memory_limit", "1024M");
define("BX_DISABLE_INDEX_PAGE", true);
mb_internal_encoding("UTF-8");
define("DBPersistent", false);
