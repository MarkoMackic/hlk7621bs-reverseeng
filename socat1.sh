#/bin/sh

echo "Starting port redirection"

/socat-mipsel32-static-debian-squeeze -d -d  -x /dev/ttyUSB$PN,cfmakeraw,b1000000,unlink-close=0,sync pty,link=/dev/ttyDEV$PN,rawer &

wait


