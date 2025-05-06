#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run by root' >&2
    exit 1
fi

mkdir -p caddy/config caddy/data
apt install -y gettext jq

current_cc=$(sysctl -n net.ipv4.tcp_congestion_control)

# Enable BBR, if it is not in place
if [ "$current_cc" != "bbr" ]; then
    echo 'net.core.default_qdisc=fq' > /etc/sysctl.d/10-custom-kernel-bbr.conf
    echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.d/10-custom-kernel-bbr.conf
    service procps force-reload
fi

# Install Docker - if not installed
if ! command -v docker &> /dev/null; then
    wget -O - https://get.docker.com | sudo bash 
fi

# Removing watchtower - not a problem if it was installed by Outline
if docker ps -a --format '{{.Names}}' | grep -q "^watchtower$"; then
    echo 'Watchtower detected, removing.'
    docker stop watchtower
    docker rm watchtower
fi

# Get user defined variables
read -p "DNS name of the site: " DOMAIN_NAME
read -p "Outline's IP & port for Cloak ('IP:port'): " OUTLINE_IP_PORT

touch .env cloak-server.conf  Caddyfile # to keep them as a files during first Docker start

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

export $(cat .env | xargs)
envsubst < cloak-server_template.conf > cloak-server.conf
envsubst < Caddyfile_template > Caddyfile

docker compose up -d

echo "Client's config values:"
echo '"UID": "'$CLOAK_USER_UID'"'
echo '"PublicKey": "'$CLOAK_PUBLIC_KEY'"'
echo '"ServerName": "'$DOMAIN_NAME'"'
echo
echo '(do `docker compose down` to remove)'