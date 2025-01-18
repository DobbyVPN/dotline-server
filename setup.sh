#!/bin/bash

touch logs.txt
touch .env
exec > >(tee -a logs.txt) 2>&1

function outline_processing {
    CLOAK_SERVER_PORT=8443
    OUTLINE_API_PORT=8453
    OUTLINE_KEYS_PORT=8454
    SPECIAL_URL=$(echo `head /dev/urandom | tr -dc A-Za-z0-9 | head -c40`)

    wget -O - https://raw.githubusercontent.com/Jigsaw-Code/outline-apps/master/server_manager/install_scripts/install_server.sh | sudo bash -s -- --hostname 127.0.0.1 --api-port $OUTLINE_API_PORT --keys-port $OUTLINE_KEYS_PORT

    docker ps --format "{{.Names}}" | sort | xargs --verbose --max-args=1 -- docker stop
    docker ps -a --format "{{.Names}}" | sort | xargs --verbose --max-args=1 -- docker rm

    OUTLINE_API_PREFIX=$(tac /opt/outline/access.txt | rev | grep '/' | cut -d'/' -f1 | rev)
    docker run --rm -v $(pwd)/.env:/app/.env ghcr.io/dobbyvpn/dobbyvpn-server/cloak-server:v2 sh -c "
KEYPAIRS=\$(/app/ck-server -key)
cat << EOF >> /app/.env
CLOAK_PRIVATE_KEY=\$(echo \$KEYPAIRS | cut -d' ' -f13)
CLOAK_PUBLIC_KEY=\$(echo \$KEYPAIRS | cut -d' ' -f5)
CLOAK_USER_UID=\$(/app/ck-server -uid | cut -d' ' -f4)
CLOAK_ADMIN_UID=\$(/app/ck-server -uid | cut -d' ' -f4)
EOF"

cat << EOF >> ".env"
OUTLINE_API_PORT=${OUTLINE_API_PORT}
OUTLINE_KEYS_PORT=${OUTLINE_KEYS_PORT}
OUTLINE_API_PREFIX=${OUTLINE_API_PREFIX}
CLOAK_SERVER_PORT=${CLOAK_SERVER_PORT}
DOMAIN_NAME=${DOMAIN_NAME}
SPECIAL_URL=${SPECIAL_URL}
EOF
}

function awg_processing {
cat << EOF >> ".env"
DOMAIN_NAME=${DOMAIN_NAME}
CLOAK_SERVER_PORT=33333
OUTLINE_API_PORT=33333
EOF

}


function xray_processing {
    XRAY_CLIENT_UUID=$(echo `uuidgen`)
	
    # It is only for certificates generation only
    docker run -d \
  --name caddy_outline \
  --publish 443:443/tcp \
  --env DOMAIN_NAME=${DOMAIN_NAME} \
  --env SPECIAL_URL=fake \
  --env CLOAK_SERVER_PORT=33333 \
  --volume $(pwd)/caddy/Caddyfile_outline:/etc/caddy/Caddyfile \
  --volume $(pwd)/caddy/data:/data \
  --volume $(pwd)/caddy/config:/config \
  caddy:2.8.4

    sleep 3
    while ! test -d "./caddy/data/caddy/certificates"; do
        sleep 1
    done
    docker stop "caddy_outline"
    docker rm "caddy_outline"

    cat << EOF >> ".env"
DOMAIN_NAME=${DOMAIN_NAME}
CERT_DIR=./caddy/data/caddy/certificates/acme-v02.api.letsencrypt.org-directory
XRAY_CLIENT_UUID=${XRAY_CLIENT_UUID}
CLOAK_SERVER_PORT=33333
OUTLINE_API_PORT=33333
EOF

}

# Start main flow
read -e -p "Enter Domain Name: " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    echo "Error: you didn't enter domain name!" >&2
    exit 1
fi

echo "Choose the proxy server:"
echo "1 - outline"
echo "2 - awg"
echo "3 - xray"
read -p "Your choice (1, 2 or 3): " user_choice

case "$user_choice" in
1)
    choice_number=1
    choice_name="outline"
    ;;
2)
    choice_number=2
    choice_name="awg"
    ;;
3)
    choice_number=3
    choice_name="xray"
    ;;
*)
    echo "ERROR: Wrong input. Try again!."
    get_choice # Recursion if wrong choice
    ;;
esac

wget -O - https://get.docker.com | sudo bash 

if [ "$choice_number" -eq 1 ]; then
    outline_processing
elif [ "$choice_number" -eq 2 ]; then
    awg_processing
elif [ "$choice_number" -eq 3 ]; then
    xray_processing
fi

echo "Starting docker compose..."
docker compose -f docker-compose.yaml --profile $choice_name up -d

echo "All logs have been saved in logs.txt"
