#/bin/sh

echo "killing all remote applications related to basestation work ..."

ps | awk '/socat-mipsel32-static-debian-sqeeze/{system("kill " $1)}' 
ps | awk '/zk_ap_keep_running/{system("kill " $1)}'
ps | awk '/mqtt_client/{system("kill " $1)}'

