#!/bin/bash
# =============================================================================
# 🚀 JITSI AGRO-CLUSTER v17.0 (DOCKER-BASED / PROXMOX AUTOMATION)
# ────────────────────────────────────────────────────────────────────────────
# ✅ Настройка по принципу "Вставил и забыл"
# ✅ Автоматический брендинг и регистрация пользователей
# ✅ Распределенная архитектура: Main + 2 JVB + Jibri
# =============================================================================
set -euo pipefail

# --- CONFIG ---
SSD_STORAGE="ssd-storage"
HDD_STORAGE="hdd-storage"
BRIDGE="vmbr17"
VLAN_TAG="17"
GW="10.1.17.1"
TEMPLATE_ID=108 # ID вашего шаблона

USER_NAME="vardo001"
USER_PASS="!P09710023p"
PUBLIC_FQDN="vks.ahprostory.ru"
PUBLIC_URL="https://vks.ahprostory.ru"

VMS=(
  "130:jitsi-main:10.1.17.130:8192:4"
  "131:jitsi-jvb-1:10.1.17.131:16384:8"
  "132:jitsi-jvb-2:10.1.17.132:16384:8"
  "133:jitsi-jibri:10.1.17.133:8192:4"
)

# --- CLOUD-INIT SNIPPET ---
mkdir -p /var/lib/vz/snippets
cat > /var/lib/vz/snippets/jitsi_final_agro.yaml <<EOF
#cloud-config
user: ${USER_NAME}
password: ${USER_PASS}
chpasswd: { expire: False }
ssh_pwauth: True
sudo: ['ALL=(ALL) NOPASSWD:ALL']
groups: [sudo, docker]
packages: [qemu-guest-agent, docker.io, docker-compose-plugin, git, ufw, curl, sshpass, parted]

write_files:
  - path: /usr/local/bin/agro-init.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      exec > >(tee -a /var/log/agro-deploy.log) 2>&1
      echo ">>> Инициализация Jitsi на \$(hostname)..."
      
      systemctl enable --now qemu-guest-agent docker
      H=\$(hostname)
      
      # Официальная рекомендация: Настройка Firewall
      ufw --force reset; ufw default deny incoming; ufw allow ssh; ufw allow from 10.1.17.0/24
      [ "\$H" = "jitsi-main" ] && ufw allow 80,443,3478,5349/tcp && ufw allow 3478/udp
      [[ "\$H" == jitsi-jvb* ]] && ufw allow 10000/udp
      ufw --force enable

      # Клонирование и настройка Docker-Jitsi
      mkdir -p /home/${USER_NAME}/jitsi && cd /home/${USER_NAME}/jitsi
      git clone https://github.com/jitsi/docker-jitsi-meet .
      cp env.example .env && ./gen-passwords.sh
      
      # Автоматическая правка .env (Handbook compliant)
      sed -i "s|^PUBLIC_URL.*|PUBLIC_URL=${PUBLIC_URL}|" .env
      sed -i "s|^#ENABLE_AUTH=1|ENABLE_AUTH=1|" .env
      sed -i "s|^#ENABLE_GUESTS=1|ENABLE_GUESTS=1|" .env
      sed -i "s|^#AUTH_TYPE=internal|AUTH_TYPE=internal|" .env

      if [ "\$H" = "jitsi-main" ]; then
        docker compose up -d
        sleep 60
        # Регистрация администратора
        docker compose exec -T prosody prosodyctl --config /config/prosody.cfg.lua register admin ${PUBLIC_FQDN} '@groAdm54' || true
        # Брендинг Агрохолдинга
        CFG="/home/${USER_NAME}/.jitsi-meet-cfg/web"
        mkdir -p \$CFG
        docker compose exec -T web cat /defaults/interface_config.js > \$CFG/interface_config.js
        sed -i "s/Jitsi Meet/Агрохолдинг Просторы/g" \$CFG/interface_config.js
        sed -i "s/SHOW_JITSI_WATERMARK: true/SHOW_JITSI_WATERMARK: false/g" \$CFG/interface_config.js
        docker compose restart web
      elif [[ "\$H" == jitsi-jvb* ]]; then
        # Настройка моста (Video Bridge)
        echo "JVB_ADVERTISED_IPS=\$(hostname -I | awk '{print \$1}')" >> .env
        docker compose up -d jvb
      elif [ "\$H" = "jitsi-jibri" ]; then
        # Настройка записи на диск 500ГБ
        if [ -b /dev/sdb ]; then
          parted -s /dev/sdb mklabel gpt mkpart primary ext4 0% 100%
          mkfs.ext4 /dev/sdb1; mkdir -p /srv/recordings
          echo "/dev/sdb1 /srv/recordings ext4 defaults 0 2" >> /etc/fstab && mount -a
          mkdir -p /home/${USER_NAME}/.jitsi-meet-cfg/jibri/recordings
          echo "/srv/recordings /home/${USER_NAME}/.jitsi-meet-cfg/jibri/recordings none bind 0 0" >> /etc/fstab && mount -a
        fi
        modprobe snd-aloop && docker compose -f docker-compose.yml -f jibri.yml up -d jibri
      fi
      echo ">>> Установка на \$(hostname) завершена."
runcmd:
  - /usr/local/bin/agro-init.sh
EOF

# --- ДЕПЛОЙ В PROXMOX ---
for VM_DATA in "${VMS[@]}"; do
  IFS=':' read -r VMID NAME IP RAM CPU <<< "$VM_DATA"
  echo ">>> Подготовка $NAME ($VMID)..."
  qm stop $VMID --skiplock 1 2>/dev/null || true
  qm destroy $VMID --purge --skiplock 1 2>/dev/null || true
  
  qm clone $TEMPLATE_ID $VMID --name $NAME --full
  qm set $VMID --memory $RAM --cores $CPU --agent 1
  qm set $VMID --net0 virtio,bridge=$BRIDGE,tag=$VLAN_TAG
  qm set $VMID --ipconfig0 ip=$IP/24,gw=$GW
  qm set $VMID --ciuser $USER_NAME --cipassword $USER_PASS
  qm set $VMID --cicustom "user=local:snippets/jitsi_final_agro.yaml"
  [ "$VMID" = "133" ] && qm set "$VMID" --scsi1 ${HDD_STORAGE}:500
  qm start $VMID
done

echo ">>> Скрипт запущен. Ожидайте 10 минут, пока Cloud-Init завершит настройку всех машин."
echo "Портал будет доступен по адресу: ${PUBLIC_URL}"
