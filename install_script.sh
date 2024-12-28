#!/bin/bash

function main {
    
    CLOAK_SERVER_PORT=8443
    OUTLINE_API_PORT=11111
    OUTLINE_KEYS_PORT=22222    

    read -e -p "Enter Domain Name: " DOMAIN_NAME
    if [ -z "$DOMAIN_NAME" ]; then
        echo "Error: you didn't enter domain name!" >&2
        exit 1
    fi
    SPECIAL_URL=$(echo `head /dev/urandom | tr -dc A-Za-z0-9 | head -c40`)

    # wget -O - https://get.docker.com | sudo bash # this line is needed!!

    wget -O - https://raw.githubusercontent.com/Jigsaw-Code/outline-apps/master/server_manager/install_scripts/install_server.sh | sudo bash -s -- --hostname 127.0.0.1 --api-port $OUTLINE_API_PORT --keys-port $OUTLINE_KEYS_PORT

    docker ps --format "{{.Names}}" | sort | xargs --verbose --max-args=1 -- docker stop
    docker ps -a --format "{{.Names}}" | sort | xargs --verbose --max-args=1 -- docker rm


    OUTLINE_API_PREFIX=$(tac /opt/outline/access.txt | rev | grep '/' | cut -d'/' -f1 | rev)

    touch .env
    docker run --rm -v $(pwd)/.env:/app/.env ghcr.io/dobbyvpn/dobbyvpn-server/cloak-server:v2.10.0 sh -c "
    KEYPAIRS=\$(/app/ck-server -key)
    CLOAK_PRIVATE_KEY=\$(echo \$KEYPAIRS | cut -d' ' -f13)
    CLOAK_PUBLIC_KEY=\$(echo \$KEYPAIRS | cut -d' ' -f5)
    CLOAK_USER_UID=\$(/app/ck-server -uid | cut -d' ' -f4)
    CLOAK_ADMIN_UID=\$(/app/ck-server -uid | cut -d' ' -f4)

    echo \"CLOAK_PRIVATE_KEY=\$CLOAK_PRIVATE_KEY\" >> /app/.env
    echo \"CLOAK_PUBLIC_KEY=\$CLOAK_PUBLIC_KEY\" >> /app/.env
    echo \"CLOAK_USER_UID=\$CLOAK_USER_UID\" >> /app/.env
    echo \"CLOAK_ADMIN_UID=\$CLOAK_ADMIN_UID\" >> /app/.env
    "

    echo "OUTLINE_API_PORT=${OUTLINE_API_PORT}" >> ".env"
    echo "OUTLINE_KEYS_PORT=${OUTLINE_KEYS_PORT}" >> ".env"
    echo "OUTLINE_API_PREFIX=${OUTLINE_API_PREFIX}" >> ".env"
    echo "CLOAK_SERVER_PORT=${CLOAK_SERVER_PORT}" >> ".env"
    echo "DOMAIN_NAME=${DOMAIN_NAME}" >> ".env"
    echo "SPECIAL_URL=${SPECIAL_URL}" >> ".env"

    echo "Starting docker compose..."
    docker compose -f docker-compose.yaml up -d

    echo "All logs have been saved in logs.txt"
    echo "Done!"
}

main

