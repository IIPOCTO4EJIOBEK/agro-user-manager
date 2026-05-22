<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
global $DB;

echo "=== Adding UF_PUBLIC field ===\n\n";

// Check if field exists
$res = $DB->Query("SELECT ID FROM b_user_field WHERE FIELD_NAME = 'UF_PUBLIC' AND ENTITY_ID = 'USER'");
if($res->Fetch()) {
    echo "UF_PUBLIC already exists\n";
} else {
    echo "Creating UF_PUBLIC field...\n";
    
    // Get max SORT value
    $r = $DB->Query("SELECT MAX(SORT) as MAX_SORT FROM b_user_field WHERE ENTITY_ID = 'USER'");
    $row = $r->Fetch();
    $sort = intval($row['MAX_SORT']) + 100;
    
    // Insert into b_user_field
    $sql = "INSERT INTO b_user_field (ENTITY_ID, FIELD_NAME, USER_TYPE_ID, SORT, MULTIPLE, MANDATORY, SHOW_FILTER, SHOW_IN_LIST, EDIT_IN_LIST, IS_SEARCHABLE, SETTINGS)
            VALUES ('USER', 'UF_PUBLIC', 'boolean', $sort, 'N', 'N', 'N', 'N', 'N', 'N', 'a:0:{}')";
    
    if($DB->Query($sql)) {
        $r = $DB->Query("SELECT LAST_INSERT_ID() as ID");
        $row = $r->Fetch();
        $fieldId = $row['ID'];
        echo "Created UF_PUBLIC with ID: $fieldId\n";
        
        // Add language settings
        $DB->Query("INSERT INTO b_user_field_lang (USER_FIELD_ID, LANGUAGE_ID, EDIT_FORM_LABEL, EDIT_FORM_LABEL_2, LIST_COLUMN_LABEL, LIST_FILTER_LABEL, ERROR_MESSAGE)
                    VALUES ($fieldId, 'ru', 'Публичный профиль', '', 'Публичный профиль', 'Публичный профиль', '')");
        $DB->Query("INSERT INTO b_user_field_lang (USER_FIELD_ID, LANGUAGE_ID, EDIT_FORM_LABEL, EDIT_FORM_LABEL_2, LIST_COLUMN_LABEL, LIST_FILTER_LABEL, ERROR_MESSAGE)
                    VALUES ($fieldId, 'en', 'Public Profile', '', 'Public Profile', 'Public Profile', '')");
        
        echo "Added language labels\n";
    } else {
        echo "Error: ".$DB->GetErrorMessage()."\n";
    }
}

// Check if column exists in b_uts_user
echo "\nChecking b_uts_user.UF_PUBLIC column...\n";
$res = $DB->Query("SHOW COLUMNS FROM b_uts_user LIKE 'UF_PUBLIC'");
if($res->Fetch()) {
    echo "Column UF_PUBLIC exists in b_uts_user\n";
} else {
    echo "Adding UF_PUBLIC column to b_uts_user...\n";
    if($DB->Query("ALTER TABLE b_uts_user ADD COLUMN UF_PUBLIC CHAR(1) DEFAULT NULL")) {
        echo "Column added successfully\n";
    } else {
        echo "Error: ".$DB->GetErrorMessage()."\n";
    }
}

// Verify
echo "\n=== Verification ===\n";
$res = $DB->Query("SELECT ID, FIELD_NAME, USER_TYPE_ID FROM b_user_field WHERE FIELD_NAME = 'UF_PUBLIC'");
if($f = $res->Fetch()) {
    echo "Field: ID={$f['ID']} NAME={$f['FIELD_NAME']} TYPE={$f['USER_TYPE_ID']}\n";
}

$res = $DB->Query("SHOW COLUMNS FROM b_uts_user LIKE 'UF_PUBLIC'");
if($c = $res->Fetch()) {
    echo "Column: {$c['Field']} Type: {$c['Type']}\n";
}

echo "\n=== Complete ===\n";
echo "Clear cache and try again\n";
?>
