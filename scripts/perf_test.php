<?php
$start = microtime(true);
for ($i = 0; $i < 10000; $i++) {
    $f = @fopen(__DIR__.'/bitrix/tmp/test_'.$i, 'w');
    if ($f) {
        fwrite($f, 'test');
        fclose($f);
        unlink(__DIR__.'/bitrix/tmp/test_'.$i);
    }
}
echo 'Time for 10k ops in tmpfs: '.(microtime(true) - $start).'s\n';

$start = microtime(true);
for ($i = 0; $i < 1000; $i++) {
    $f = @fopen(__DIR__.'/upload/test_'.$i, 'w');
    if ($f) {
        fwrite($f, 'test');
        fclose($f);
        unlink(__DIR__.'/upload/test_'.$i);
    }
}
echo 'Time for 1k ops in NFS (upload): '.(microtime(true) - $start).'s\n';
?>
