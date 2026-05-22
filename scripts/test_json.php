<?php
$content = file_get_contents('/home/bitrix/www/apply_structure.php');
$start = strpos($content, "\$json = '");
if($start === false) die("Start not found\n");
$start += strlen("\$json = '");
$end = strpos($content, "';", $start);
if($end === false) die("End not found\n");
$jsonStr = substr($content, $start, $end - $start);
echo "Extracted length: ".strlen($jsonStr)."\n";
$flat = json_decode($jsonStr, true);
if(!$flat) die("Decode error: ".json_last_error_msg()."\n");
echo "Decoded ".count($flat)." items\n";
echo "First item: ".json_encode($flat[0])."\n";
?>
