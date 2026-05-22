<?php
define('NOT_CHECK_PERMISSIONS', true);
require_once('/home/bitrix/www/bitrix/modules/main/include/prolog_before.php');
CModule::IncludeModule('intranet');
CModule::IncludeModule('humanresources');

header('Content-Type: application/json');

$result = [
    'intranet_iblock_id' => COption::GetOptionInt("intranet", "iblock_structure"),
    'hr_structure_id' => COption::GetOptionString("humanresources", "structure_id"),
    'nodes_count' => $DB->Query("SELECT COUNT(*) as CNT FROM b_hr_structure_node")->Fetch()['CNT'],
    'relations_count' => $DB->Query("SELECT COUNT(*) as CNT FROM b_hr_structure_node_relation")->Fetch()['CNT'],
    'root_node' => $DB->Query("SELECT ID, NAME FROM b_hr_structure_node WHERE PARENT_ID = 0")->Fetch(),
];

echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
