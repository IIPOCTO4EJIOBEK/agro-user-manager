<?php
$_SERVER['DOCUMENT_ROOT'] = '/home/bitrix/www';
define('NO_KEEP_STATISTIC', true);
define('NOT_CHECK_PERMISSIONS', true);
require($_SERVER['DOCUMENT_ROOT'] . '/bitrix/modules/main/include/prolog_before.php');

if (CModule::IncludeModule('ldap')) {
    echo "Syncing LDAP server ID 2...\n";
    $result = CLDAPServer::Sync(2);
    echo "Sync result: " . ($result ? 'Success' : 'Failed') . "\n";
} else {
    echo "LDAP module not found\n";
}
