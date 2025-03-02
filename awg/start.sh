#!/bin/bash

# Awg server config generation
sh config.sh

# Awg server reload cycle
echo "[$(date)] AmneziaWG server up" >> awg.log
config_hash=$(sha1sum wg0.conf)
awg-quick up wg0 >> awg.log 2>&1

while true; do
	new_config_hash=$(sha1sum wg0.conf)

	if [ "$config_hash" != "$new_config_hash" ]; then
		echo "[$(date)] AmneziaWG server down" >> awg.log
		awg-quick down wg0 >> awg.log 2>&1

		echo "[$(date)] AmneziaWG server re-up" >> awg.log
		awg-quick up wg0 >> awg.log 2>&1

		config_hash=$new_config_hash
	fi

	sleep 5
done

tail -f /dev/null
