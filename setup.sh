#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run by root' >&2
    exit 1
fi

mkdir -p caddy/config caddy/data
apt install -y gettext jq

current_cc=$(sysctl -n net.ipv4.tcp_congestion_control)

# Enable BBR, if not in place
if [ "$current_cc" != "bbr" ]; then
    cat << EOF >> /etc/sysctl.d/10-custom-kernel-bbr.conf
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
    service procps force-reload
fi

# Install Docker - if not installed
if ! command -v docker &> /dev/null; then
    wget -O - https://get.docker.com | sudo bash 
fi


read -p "Enter 'face' domain name: " DOMAIN_NAME
read -p "Enter Outline's IP & port (as 'IP:port'): " OUTLINE_IP_PORT

touch .env

# Configuring Cloak server
docker run --rm -v $(pwd)/.env:/.env ghcr.io/dobbyvpn/dobbyvpn-server/cloak-server:v2 sh -c \
"KEYPAIRS=\$(/app/ck-server -key)
cat << EOF >> /.env
CLOAK_PRIVATE_KEY=\$(echo \$KEYPAIRS | cut -d' ' -f13)
CLOAK_PUBLIC_KEY=\$(echo \$KEYPAIRS | cut -d' ' -f5)
CLOAK_USER_UID=\$(/app/ck-server -uid | cut -d' ' -f4)
CLOAK_ADMIN_UID=\$(/app/ck-server -uid | cut -d' ' -f4)
EOF"

CLOAK_SECRET_URL=$(echo `head /dev/urandom | tr -dc A-Za-z0-9 | head -c40`)

cat << EOF >> ".env"
CLOAK_SECRET_URL=${CLOAK_SECRET_URL}
DOMAIN_NAME=${DOMAIN_NAME}
OUTLINE_IP_PORT=${OUTLINE_IP_PORT}
EOF

envsubst < cloak-server_template.conf > cloak-server.conf

docker compose up -d

echo "Client's config values:"
echo '"UID": "'$CLOAK_USER_UID'"'
echo '"PublicKey": "'$CLOAK_PUBLIC_KEY'"'
echo '"ServerName": "'$DOMAIN_NAME'"'