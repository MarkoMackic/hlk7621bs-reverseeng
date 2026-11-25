#!/bin/bash
date=$(printf "%(%d_%m_%Y)T\n" -1)
logs="./logs/$date/"

if [ "$1" ]; then
  logs=$1
fi

if [ ! -d $logs ]; then
  	echo "directory \"$logs\" doesn't not exist, will be created"
	mkdir -p $logs
fi

# start mqtt broker
killall zancudo 
zancudo --broker $MT_MQTT_BROKER --no-color 2>&1 | tee "$logs/mqtt.log" &
# kill all processess related to bs work
sshpass -e ssh basestation sh < kill_all_remote.sh 2>&1
# start main app
sshpass -e ssh basestation sh < mqtt_client.sh 2>&1 | tee "$logs/client.log" &
# wait for 10 secs 
sleep 10
# start port redirection
sshpass -e ssh basestation sh < socat.sh 2>&1 | tee "$logs/socat.log" &



wait

