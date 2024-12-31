#!/bin/bash

touch logs.txt
exec > >(tee -a logs.txt) 2>&1

CLOAK_SERVER_PORT=8443
OUTLINE_API_PORT=8453
OUTLINE_KEYS_PORT=8454 
SPECIAL_URL=$(echo `head /dev/urandom | tr -dc A-Za-z0-9 | head -c40`)

read -e -p "Enter Domain Name: " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    echo "Error: you didn't enter domain name!" >&2
    exit 1
fi

if ! host "$DOMAIN_NAME" > /dev/null 2>&1; then
    echo "Error: invalid or non-existent domain name!" >&2
    exit 1
fi
echo "Domain name is valid: $DOMAIN_NAME"

wget -O - https://get.docker.com | sudo bash 
wget -O - https://raw.githubusercontent.com/Jigsaw-Code/outline-apps/master/server_manager/install_scripts/install_server.sh | sudo bash -s -- --hostname 127.0.0.1 --api-port $OUTLINE_API_PORT --keys-port $OUTLINE_KEYS_PORT

docker ps --format "{{.Names}}" | sort | xargs --verbose --max-args=1 -- docker stop
docker ps -a --format "{{.Names}}" | sort | xargs --verbose --max-args=1 -- docker rm

OUTLINE_API_PREFIX=$(tac /opt/outline/access.txt | rev | grep '/' | cut -d'/' -f1 | rev)

touch .env
docker run --rm -v $(pwd)/.env:/app/.env ghcr.io/dobbyvpn/dobbyvpn-server/cloak-server:v2.10.0 sh -c "
KEYPAIRS=$(/app/ck-server -key)
cat << EOF >> /app/.env
CLOAK_PRIVATE_KEY=$(echo $KEYPAIRS | cut -d' ' -f13)
CLOAK_PUBLIC_KEY=$(echo $KEYPAIRS | cut -d' ' -f5)
CLOAK_USER_UID=$(/app/ck-server -uid | cut -d' ' -f4)
CLOAK_ADMIN_UID=$(/app/ck-server -uid | cut -d' ' -f4)
EOF"

cat << EOF >> ".env"
OUTLINE_API_PORT=${OUTLINE_API_PORT}
OUTLINE_KEYS_PORT=${OUTLINE_KEYS_PORT}
OUTLINE_API_PREFIX=${OUTLINE_API_PREFIX}
CLOAK_SERVER_PORT=${CLOAK_SERVER_PORT}
DOMAIN_NAME=${DOMAIN_NAME}
SPECIAL_URL=${SPECIAL_URL}
EOF

echo "Starting docker compose..."
docker compose -f docker-compose.yaml up -d

echo "All logs have been saved in logs.txt"
echo "Done!"
