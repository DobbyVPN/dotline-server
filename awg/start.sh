#!/bin/bash

config_hash=$(sha1sum wg0.conf)
echo "[$(date)] awg server initialisation" >> awg.log
awg-quick up wg0 >> awg.log 2>&1

while true; do
	new_config_hash=$(sha1sum wg0.conf)

	if [ "$config_hash" != "$new_config_hash" ]; then
		config_hash=$new_config_hash
		echo "[$(date)] awg server down" >> awg.log
		awg-quick down wg0 >> awg.log 2>&1
		echo "[$(date)] awg server up" >> awg.log
		awg-quick up wg0 >> awg.log 2>&1
	fi

	sleep 5
done

tail -f /dev/null
