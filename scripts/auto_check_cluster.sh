#!/bin/bash
PASS="!P09710023p"
RPASS="B1tr1x_R3d1s_S3cur3_P@ssw0rd_2026!"

echo "=== CLUSTER HEALTH CHECK ==="

check_ssh() {
    local ip=$1
    local name=$2
    echo -n "Checking $name ($ip)... "
    if sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$ip "echo OK" >/dev/null 2>&1; then
        echo "SSH OK"
    else
        echo "SSH FAILED"
    fi
}

check_redis() {
    echo "Checking Redis (10.0.1.210)..."
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@10.0.1.210 "redis-cli -a '$RPASS' --no-auth-warning PING"
}

check_mysql() {
    echo "Checking MySQL Primary (10.0.1.200)..."
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@10.0.1.200 "mysqladmin -u root ping"
    echo "Checking MySQL Replica (10.0.1.201)..."
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@10.0.1.201 "mysqladmin -u root ping"
}

check_web() {
    for ip in 220 221 222; do
        echo "Checking Web Node 10.0.1.$ip..."
        sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@10.0.1.$ip "systemctl is-active nginx && systemctl is-active php-fpm"
    done
}

check_push() {
    echo "Checking Push Server (10.0.1.230)..."
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@10.0.1.230 "ps aux | grep node | grep -v grep | wc -l"
}

check_ssh 10.0.1.50 "HAProxy"
check_ssh 10.0.1.210 "Redis"
check_ssh 10.0.1.200 "MySQL Primary"
check_ssh 10.0.1.201 "MySQL Replica"
check_ssh 10.0.1.220 "Web 1"
check_ssh 10.0.1.221 "Web 2"
check_ssh 10.0.1.222 "Web 3"
check_ssh 10.0.1.230 "Push"

echo ""
check_redis
check_mysql
check_web
check_push
