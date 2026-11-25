#/bin/sh

echo "Starting port redirection"

/socat-mipsel32-static-debian-squeeze -d -d /dev/ttyUSB1,cfmakeraw,b1000000,unlink-close=0,sync pty,link=/dev/ttyDEV1,rawer & #>/dev/null 2>&1 &
/socat-mipsel32-static-debian-squeeze -d -d /dev/ttyUSB2,cfmakeraw,b1000000,unlink-close=0,sync pty,link=/dev/ttyDEV2,rawer & #>/dev/null 2>&1 &
/socat-mipsel32-static-debian-squeeze -d -d /dev/ttyUSB3,cfmakeraw,b1000000,unlink-close=0,sync pty,link=/dev/ttyDEV3,rawer & #>/dev/null 2>&1 &

/socat-mipsel32-static-debian-squeeze -d -d  -x /dev/ttyUSB0,cfmakeraw,b1000000,unlink-close=0,sync pty,link=/dev/ttyDEV0,rawer &

wait


