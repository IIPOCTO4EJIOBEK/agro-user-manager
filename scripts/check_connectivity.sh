#!/bin/bash
HOSTS=("10.0.1.110" "10.0.1.200" "10.0.1.201" "10.0.1.210" "10.0.1.220" "10.0.1.221" "10.0.1.222" "10.0.1.230" "10.0.1.50")
SSH_USER="vardo001"
SSH_PASS="!P09710023p"

echo "Checking connectivity and ports..."

for host in "${HOSTS[@]}"; do
    echo "--- Host: $host ---"
    if ping -c 1 -W 1 "$host" > /dev/null; then
        echo "Ping: OK"
    else
        echo "Ping: FAILED"
    fi

    # Check SSH
    if sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 "$SSH_USER@$host" "echo 'SSH: OK'" 2>/dev/null; then
        echo "SSH: OK"
    else
        echo "SSH: FAILED"
    fi

    # Check common ports based on role (from CLUSTER_MAP)
    case $host in
        "10.0.1.110") # NPM
            nc -zv -w 1 "$host" 80 443 81 8893 8894 8895 2>&1 | grep -v "failed" || echo "NPM Ports: FAILED"
            ;;
        "10.0.1.50") # HAProxy
            nc -zv -w 1 "$host" 80 443 8893 8894 8895 2>&1 | grep -v "failed" || echo "HAProxy Ports: FAILED"
            ;;
        "10.0.1.210") # Redis
            nc -zv -w 1 "$host" 6379 2>&1 | grep -v "failed" || echo "Redis Port: FAILED"
            ;;
        "10.0.1.200"|"10.0.1.201") # DB
            nc -zv -w 1 "$host" 3306 5432 80 443 2>&1 | grep -v "failed" || echo "DB Ports: FAILED"
            ;;
        "10.0.1.220"|"10.0.1.221"|"10.0.1.222") # Web
            nc -zv -w 1 "$host" 80 443 8888 2>&1 | grep -v "failed" || echo "Web Ports: FAILED"
            ;;
        "10.0.1.230") # Push
            nc -zv -w 1 "$host" 8010 8011 8012 8013 8014 8015 9010 9011 8893 8895 2>&1 | grep -v "failed" || echo "Push Ports: FAILED"
            ;;
    esac
    echo ""
done
