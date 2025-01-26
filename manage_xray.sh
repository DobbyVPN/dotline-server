#!/bin/bash

CONFIG_FILE="xray/config.json"

# Проверка наличия файла
if [ ! -f "$CONFIG_FILE" ]; then
  echo "File $CONFIG_FILE is not found!"
  exit 1
fi

#для гинерации UUID v4
generate_uuid() {
  cat /proc/sys/kernel/random/uuid
}

add_user() {

  # Добавление uuid
  UUID=$(generate_uuid)
  jq ".inbounds[].settings.clients += [{\"id\": \"$UUID\", \"flow\": \"xtls-rprx-vision\"}]" "$CONFIG_FILE" > temp.json && mv temp.json "$CONFIG_FILE"

    echo "User with UUID $UUID has been added!"
}

delete_user() {
  echo -n "Enter UUID for deleting: "
  read USER_UUID

  if jq -e ".inbounds[].settings.clients[] | select(.id == \"$USER_UUID\")" "$CONFIG_FILE" > /dev/null; then
    jq ".inbounds[].settings.clients |= map(select(.id != \"$USER_UUID\"))" "$CONFIG_FILE" > temp.json && mv temp.json "$CONFIG_FILE"
    
    echo "User with UUID $USER_UUID has been deleted."
  else
    echo "User with UUID $USER_UUID is not found. Deletion is imposible."
  fi
}

list_users() {
  echo "List of all users:"
  jq -r ".inbounds[].settings.clients[].id" "$CONFIG_FILE" | while read -r UUID; do
    echo "- $UUID"
  done
}

# Main flow
while true; do
  echo "Select a option:"
  echo "1) Add Xray user"
  echo "2) Delete Xray user"
  echo "3) Show all Xray users"
  echo "4) Exit"
  read -p "Your choice: " CHOICE

  case $CHOICE in
    1)
      add_user
      docker restart xray-server 
      ;;
    2)
      delete_user
      docker restart xray-server
      ;;
    3)
      list_users
      ;;
    4)
      echo "Exit."
      exit 0
      ;;
    *)
      echo "Wrong choice. Try again."
      ;;
  esac
  echo ""
done

