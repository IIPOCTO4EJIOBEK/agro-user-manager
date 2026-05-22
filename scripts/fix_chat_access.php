<?php
/**
 * Chat Access Fix
 * 
 * Ensures the administrator (ID 1) is correctly joined to the general chat
 * and clears the IM module cache to resolve visibility issues.
 */
define("NO_KEEP_STATISTIC", true);
define("NOT_CHECK_PERMISSIONS", true);
$_SERVER["DOCUMENT_ROOT"] = "/home/bitrix/www";
require_once($_SERVER["DOCUMENT_ROOT"]."/bitrix/modules/main/include/prolog_before.php");

if (!CModule::IncludeModule("im")) die("IM module not found");

$userId = 1; // agroadmin
echo "Checking chat access for user $userId...\n";

// 1. Check if user is in any chats
$res = \Bitrix\Im\Model\RelationTable::getList([
    'filter' => ['USER_ID' => $userId],
    'select' => ['CHAT_ID']
]);

$chatIds = [];
while ($row = $res->fetch()) {
    $chatIds[] = $row['CHAT_ID'];
}

echo "User is in chats: " . implode(", ", $chatIds) . "\n";

// 2. Try to find the general chat
$generalChatId = \CIMChat::GetGeneralChatId();
echo "General Chat ID: $generalChatId\n";

if ($generalChatId > 0) {
    $isMember = \Bitrix\Im\Model\RelationTable::getList([
        'filter' => ['CHAT_ID' => $generalChatId, 'USER_ID' => $userId]
    ])->fetch();

    if (!$isMember) {
        echo "User is NOT in general chat. Adding...\n";
        $chat = new \CIMChat(0);
        $res = $chat->AddUser($generalChatId, $userId);
        if ($res) {
            echo "Successfully added to general chat.\n";
        } else {
            echo "Failed to add to general chat.\n";
        }
    } else {
        echo "User is already in general chat.\n";
    }
}

// 3. Clear IM cache
if (is_object($GLOBALS["CACHE_MANAGER"])) {
    $GLOBALS["CACHE_MANAGER"]->CleanDir("im");
}

echo "FINISHED.\n";
?>
