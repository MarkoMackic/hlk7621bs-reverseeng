#!/bin/bash
date=$(printf "%(%d_%m_%Y)T\n" -1)
logs="./logs/$date/"

if [ "$1" ]; then
  logs=$1   
fi

if [ -f "env.sh" ]; then
	source env.sh
fi	


if [ ! -d $logs ]; then
  	echo "directory \"$logs\" doesn't not exist, will be created"
	mkdir -p $logs
else
	i=0
	while [ -d $logs ]; do
		[ "$1" ] && break;
		logs="./logs/${date}_${i}"
		let i++;	
	done
	mkdir -p $logs
fi

kill_all_services() {
	echo "Killing mqtt proxy instances"
	killall zancudo
	echo "Killing all on AP"
	sshpass -e ssh basestation sh < kill_all_remote.sh 2>&1
}

start_mqtt_proxy() {
	mkdir -p "$logs/mqtt_packets"
	zancudo --store-publish-payload "$logs/mqtt_packets" --broker $MT_MQTT_BROKER --no-color 2>&1 | tee "$logs/mqtt.log" &
}

trap 'kill_all_services' SIGINT

kill_all_services

# start mqtt proxy
start_mqtt_proxy
# start mqtt client
sshpass -e ssh basestation sh < mqtt_client.sh 2>&1 | tee "$logs/client.log" &
# wait for 10 secs 
sleep 10
# start port redirection
cat socat1.sh | sed s/\$PN/0/g | sshpass -e ssh basestation >"$logs/socat0.log" 2>&1 &
cat socat1.sh | sed s/\$PN/1/g | sshpass -e ssh basestation >"$logs/socat1.log" 2>&1 &
cat socat1.sh | sed s/\$PN/2/g | sshpass -e ssh basestation >"$logs/socat2.log" 2>&1 &
cat socat1.sh | sed s/\$PN/3/g | sshpass -e ssh basestation >"$logs/socat3.log" 2>&1 &

##sshpass -e ssh basestation sh <<< $(cat socat1.sh | sed s/\$PN/1/) 2>&1 > "$logs/socat1.log" &
#sshpass -e ssh basestation sh <<< $(cat socat1.sh | sed s/\$PN/2/) 2>&1 > "$logs/socat2.log" &
#sshpass -e ssh basestation sh <<< $(cat socat1.sh | sed s/\$PN/3/) 2>&1 > "$logs/socat3.log" &



wait

