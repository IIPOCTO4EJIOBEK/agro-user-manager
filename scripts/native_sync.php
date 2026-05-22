<?php
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
$_SERVER['DOCUMENT_ROOT'] = '/home/bitrix/www';
require($_SERVER['DOCUMENT_ROOT'] . '/bitrix/modules/main/include/prolog_before.php');
if (CModule::IncludeModule('ldap')) {
    echo "Starting native Bitrix sync for AD 250 (ID 2)...\n";
    CLdapServer::Sync(2);
    echo "Native sync complete.\n";
}
