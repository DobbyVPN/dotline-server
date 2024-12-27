#!/bin/bash

function install_docker_compose {
    echo "Docker-compose installation..."	
    #apt-get update
    #apt-get install -y docker.io docker-compose wget git
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    sudo apt-get install docker-compose-plugin
}

function install_ss {
    echo "Outline installation..."	
    if ! [ -f "install_server.sh" ]
    then
        wget  https://raw.githubusercontent.com/Jigsaw-Code/outline-apps/master/server_manager/install_scripts/install_server.sh
        chmod u+x ./install_server.sh
    fi
}

function generate_url {
    echo `head /dev/urandom | tr -dc A-Za-z0-9 | head -c40`
}


function run_ss {
    # Accepts 2 args: $1 - api-port, $2 - keys-port
    echo "Outline server runninng..."   
    ./install_server.sh --hostname 127.0.0.1 --api-port $1 --keys-port $2 
}

function replace_caddy_holders {
    # Accepts 3 args: $1 - domain name, $2 - secret-url, $3 - cloak-server port
    sed -i "s|<domain-name>|${1}|" "$pers_dir_name/Caddyfile"
    sed -i "s|<special-url>|${2}|" "$pers_dir_name/Caddyfile"
    sed -i "s|<cloak-server-port>|${3}|" "$pers_dir_name/Caddyfile"
}


function save_credentials {
   # Function saves sensitive data to file

    echo "Saving credentials"
    for key in "${!array_creds[@]}"; do
        echo "$key=${array_creds[$key]}" >> "$pers_dir_name/$creds_filename"
    done
}

function print_credentials {
    # Prints all credentials saved in $pers_dir_name/$creds_filename
    
    cat $pers_dir_name/$creds_filename
}

function readArgs {
    read -e -p "Enter Cloak Port: " -i 8443 CLOAK_PORT
    read -e -p "Enter Api Port(outline): " -i 11111 OUTLINE_API_PORT
    read -e -p "Enter Keys Port(outline): " -i 22222 OUTLINE_KEYS_PORT
    read -e -p "Enter Domain Name: " DOMAIN_NAME

    if [ -z "$DOMAIN_NAME" ]; then
        echo "Error: you didn't enter domain name!" >&2
        exit 1
    fi
}

function stop_remove_cont_by_name {
    CONTAINER_NAME=$1
    CONTAINER_ID=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.ID}}")

    if [[ -n "$CONTAINER_ID" ]]; then
	echo "Found container: $CONTAINER_NAME (ID: $CONTAINER_ID)"
        docker stop "$CONTAINER_ID" && echo "Stopped container: $CONTAINER_NAME"
        docker rm "$CONTAINER_ID" && echo "Removed container: $CONTAINER_NAME"
    else
        echo "No container found with name: $CONTAINER_NAME"
    fi
}

function replace_holders_cloak_start {
    # replaces all holders in start script for cloak
    # $1 - keys-port for outline server
    # $2 - bind port for cloak server
    # $3 - domain name
    sed -i "s|<1>|$1|" "$pers_dir_name/cloak_start.sh"
    sed -i "s|<2>|$2|" "$pers_dir_name/cloak_start.sh"
    sed -i "s|<3>|$3|" "$pers_dir_name/cloak_start.sh"
}

function replace_holders_compose {
    # replaces all holders in docker-compose.yaml
    # $1 - api port for shadowbox
    # $2 - api prefix for shadowbox

    sed -i "s|<outline-api-port>|$1|g" "$pers_dir_name/docker-compose.yaml"
    sed -i "s|<outline-keys-port>|$2|g" "$pers_dir_name/docker-compose.yaml"
    sed -i "s|<outline-api-prefix>|$3|" "$pers_dir_name/docker-compose.yaml"
}

function create_persistent_dir {	
    if [ -d "$pers_dir_name" ]; then
    	rm -rf $pers_dir_name
    fi
    mkdir $pers_dir_name

    cp "Caddyfile-template" "$pers_dir_name/Caddyfile"
    cp "cloak_start_template.sh" "$pers_dir_name/cloak_start.sh"
    cp "cloak-server-template.conf" "$pers_dir_name/cloak-server.conf"
    cp "docker-compose-template.yaml" "$pers_dir_name/docker-compose.yaml"
	
    chmod a+x "$pers_dir_name/cloak_start.sh"
}

function test_compose {
    # It makes sense to invoke this function only after install_ss
    CONTAINER_WATCHTOWER_ID=$(docker ps --filter "name=watchtower" --format "{{.ID}}")
    CONTAINER_SHADOWBOX_ID=$(docker ps --filter "name=shadowbox" --format "{{.ID}}")

    if [[ -z "$CONTAINER_WATCHTOWER_ID" ]]; then
        echo "Error: No running container found with name 'watchtower'."
        return 1
    fi

    if [[ -z "$CONTAINER_SHADOWBOX_ID" ]]; then
        echo "Error: No running container found with name 'shadowbox'."
        return 1
    fi

    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock ghcr.io/red5d/docker-autocompose $CONTAINER_WATCHTOWER_ID $CONTAINER_SHADOWBOX_ID > dump-compose-tmp.yaml

    #we should delete in dump-compose-tmp.yaml 2 lines: hostname, SB_API_PREFIX
    #otherwise the comparison will be always failed since these values are randomly generated
    sed -i '/hostname/d' "dump-compose-tmp.yaml"
    sed -i '/SB_API_PREFIX/d' "dump-compose-tmp.yaml"
	
    tmpfile=$(mktemp)
    awk '
BEGIN { in_env = 0 }
/^ *environment:/ {
    in_env = 1;
    print $0;
    next
}
/^ *- / && in_env {
    env_lines[NR] = $0;
    next
}
/^ *[^- ]/ && in_env {
    in_env = 0;
    for (line in env_lines) print env_lines[line] | "sort";
    delete env_lines;
}
{ print $0 }
END {
    if (in_env) {
        for (line in env_lines) print env_lines[line] | "sort";
    }
}' dump-compose-tmp.yaml > $tmpfile
	
    cp $tmpfile dump-compose-tmp.yaml

    
    if diff dump-compose.yaml dump-compose-tmp.yaml > /dev/null; then
        echo "OK. dump-compose.yaml and dump-compose-tmp.yaml are identical."
    else
        echo "ERROR: dump-compose.yaml and dump-compose-tmp.yaml are different."
	echo "You should manually do the following procedures:"
	echo "1) Change docker-compose-template.yaml with respect to diff."
	echo "2) Copy  dump-compose-tmp.yaml to dump-compose.yaml."
	echo "3) Restart this script."
	exit 1
    fi
}

function get_api_prefix {
    echo `tac $1 | rev | grep '/' | cut -d'/' -f1 | rev`
}

function main {
    creds_filename="creds.txt"
    pers_dir_name="data"
    readArgs	

    install_docker_compose
    install_ss
    run_ss $OUTLINE_API_PORT $OUTLINE_KEYS_PORT
    test_compose
    stop_remove_cont_by_name "watchtower"
    stop_remove_cont_by_name "shadowbox"

    URL=$(generate_url)
    create_persistent_dir
    stop_remove_cont_by_name "caddy"
    stop_remove_cont_by_name "ck-server"
    replace_caddy_holders $DOMAIN_NAME $URL $CLOAK_PORT
    replace_holders_cloak_start $OUTLINE_KEYS_PORT $CLOAK_PORT $DOMAIN_NAME
    OUTLINE_API_PREFIX=$(get_api_prefix "/opt/outline/access.txt")
    replace_holders_compose $OUTLINE_API_PORT $OUTLINE_KEYS_PORT $OUTLINE_API_PREFIX

    echo "Starting docker compose..."
    docker compose -f $pers_dir_name/docker-compose.yaml up -d


    declare -A array_creds
    array_creds["Special-url"]=$URL

    save_credentials
    print_credentials

    echo "All credentials are saved in $creds_filename"
    echo "Done!"
}

main

