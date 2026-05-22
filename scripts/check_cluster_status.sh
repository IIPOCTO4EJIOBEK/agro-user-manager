#!/bin/bash
# Итоговая проверка кластера

LOG_FILE="/root/cluster_fix_summary.log"

echo "=== ИТОГОВАЯ ПРОВЕРКА ВСЕХ СЕРВЕРОВ ===" > $LOG_FILE
echo "Дата: $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE
echo "" >> $LOG_FILE

# Redis
echo "[Redis 10.0.1.210]" >> $LOG_FILE
ssh -o StrictHostKeyChecking=no root@10.0.1.210 "
redis-cli -h 127.0.0.1 -a 'B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!' --no-auth-warning PING 2>&1
redis-cli -h 127.0.0.1 -a 'B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!' --no-auth-warning INFO memory 2>&1 | grep -E 'maxmemory_human|used_memory_human'
" >> $LOG_FILE

# MySQL Primary
echo "" >> $LOG_FILE
echo "[MySQL Primary 10.0.1.200]" >> $LOG_FILE
ssh -o StrictHostKeyChecking=no root@10.0.1.200 "
mysqladmin -u root ping 2>&1
mysql -u root -e \"SHOW VARIABLES LIKE 'max_connections';\" 2>&1
mysql -u root -e \"SHOW VARIABLES LIKE 'innodb_buffer_pool_size';\" 2>&1
systemctl is-active httpd 2>&1
" >> $LOG_FILE

# MySQL Replica
echo "" >> $LOG_FILE
echo "[MySQL Replica 10.0.1.201]" >> $LOG_FILE
ssh -o StrictHostKeyChecking=no root@10.0.1.201 "
mysqladmin -u root ping 2>&1
" >> $LOG_FILE

# HAProxy
echo "" >> $LOG_FILE
echo "[HAProxy 10.0.1.50]" >> $LOG_FILE
ssh -o StrictHostKeyChecking=no root@10.0.1.50 "
systemctl is-active haproxy 2>&1
" >> $LOG_FILE

# Web серверы
for IP in 220 221 222; do
    echo "" >> $LOG_FILE
    echo "[Web Node 10.0.1.$IP]" >> $LOG_FILE
    ssh -o StrictHostKeyChecking=no root@10.0.1.$IP "
    systemctl is-active nginx 2>&1
    systemctl is-active php-fpm 2>&1
    " >> $LOG_FILE
done

cat $LOG_FILE
