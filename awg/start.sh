#!/bin/bash

awg-quick up wg0
while true; do sleep 1; done

tail -f /dev/null
