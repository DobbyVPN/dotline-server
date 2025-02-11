#!/bin/bash

config_hash=$(sha1sum wg0.conf)
awg-quick up wg0
echo "[$(date)] awg server initialisation" >> awg.log

while true; do
	new_config_hash=$(sha1sum wg0.conf)

	if [ "$config_hash" != "$new_config_hash" ]; then
		config_hash=$new_config_hash
		awg-quick down wg0
		awg-quick up wg0
		echo "[$(date)] awg server reload" >> awg.log
	fi

	sleep 5
done

tail -f /dev/null
