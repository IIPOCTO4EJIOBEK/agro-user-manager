<?php
// /root/B24_Cluster_Project/scripts/fix_uf_public.php
// Скрипт для восстановления системного поля UF_PUBLIC, из-за которого ломался Интранет/Чат
$_SERVER["DOCUMENT_ROOT"] = "/home/bitrix/www";
define('NOT_CHECK_PERMISSIONS', true);
require_once($_SERVER["DOCUMENT_ROOT"].'/bitrix/modules/main/include/prolog_before.php');
global $DB;

echo "=== Adding UF_PUBLIC field (FIXED V2) ===\n\n";

$res = $DB->Query("SELECT ID FROM b_user_field WHERE FIELD_NAME = 'UF_PUBLIC' AND ENTITY_ID = 'USER'");
if($row = $res->Fetch()) {
    echo "UF_PUBLIC already exists with ID: {$row['ID']}\n";
    $fieldId = $row['ID'];
} else {
    echo "Creating UF_PUBLIC field...\n";
    $r = $DB->Query("SELECT MAX(SORT) as MAX_SORT FROM b_user_field WHERE ENTITY_ID = 'USER'");
    $row = $r->Fetch();
    $sort = intval($row['MAX_SORT']) + 100;
    
    $sql = "INSERT INTO b_user_field (ENTITY_ID, FIELD_NAME, USER_TYPE_ID, SORT, MULTIPLE, MANDATORY, SHOW_FILTER, SHOW_IN_LIST, EDIT_IN_LIST, IS_SEARCHABLE, SETTINGS)
            VALUES ('USER', 'UF_PUBLIC', 'boolean', $sort, 'N', 'N', 'N', 'N', 'N', 'N', 'a:0:{}')";
    
    if($DB->Query($sql)) {
        $r = $DB->Query("SELECT LAST_INSERT_ID() as ID");
        $row = $r->Fetch();
        $fieldId = $row['ID'];
        echo "Created UF_PUBLIC with ID: $fieldId\n";
    } else {
        echo "Error creating field: ".$DB->GetErrorMessage()."\n";
        die();
    }
}

// Добавляем переводы для корректного отображения в админке
$res = $DB->Query("SELECT * FROM b_user_field_lang WHERE USER_FIELD_ID = $fieldId");
if(!$res->Fetch()) {
    echo "Adding language labels...\n";
    $cols = [];
    $res = $DB->Query("SHOW COLUMNS FROM b_user_field_lang");
    while($c = $res->Fetch()) $cols[] = $c['Field'];
    
    $targetCols = ['USER_FIELD_ID', 'LANGUAGE_ID', 'EDIT_FORM_LABEL', 'LIST_COLUMN_LABEL', 'LIST_FILTER_LABEL', 'ERROR_MESSAGE'];
    if(in_array('HELP_MESSAGE', $cols)) $targetCols[] = 'HELP_MESSAGE';
    
    $colsStr = implode(', ', $targetCols);
    
    $vals_ru = [ $fieldId, "'ru'", "'Публичный профиль'", "'Публичный профиль'", "'Публичный профиль'", "''" ];
    if(in_array('HELP_MESSAGE', $cols)) $vals_ru[] = "''";
    
    $vals_en = [ $fieldId, "'en'", "'Public Profile'", "'Public Profile'", "'Public Profile'", "''" ];
    if(in_array('HELP_MESSAGE', $cols)) $vals_en[] = "''";

    $DB->Query("INSERT INTO b_user_field_lang ($colsStr) VALUES (".implode(',', $vals_ru).")");
    $DB->Query("INSERT INTO b_user_field_lang ($colsStr) VALUES (".implode(',', $vals_en).")");
}

// Проверяем таблицу UTS
echo "\nChecking b_uts_user.UF_PUBLIC column...\n";
$res = $DB->Query("SHOW COLUMNS FROM b_uts_user LIKE 'UF_PUBLIC'");
if(!$res->Fetch()) {
    echo "Adding UF_PUBLIC column to b_uts_user...\n";
    $DB->Query("ALTER TABLE b_uts_user ADD COLUMN UF_PUBLIC CHAR(1) DEFAULT NULL");
}

// Устанавливаем всем пользователям значение 1, чтобы они появились в чатах
$DB->Query("UPDATE b_uts_user SET UF_PUBLIC = '1'");

echo "\nClearing Managed Cache...\n";
if(is_object($GLOBALS['CACHE_MANAGER'])) {
    $GLOBALS['CACHE_MANAGER']->CleanAll();
}
if(class_exists('\Bitrix\Main\ORM\Entity')) {
    \Bitrix\Main\ORM\Entity::destroy('Bitrix\Main\User');
}

echo "\n=== Complete ===\n";
?>
