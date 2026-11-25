#/bin/sh


/socat-mipsel32-static-debian-squeeze -d -d -U stdio exec:"/mqtt_client_mod_port",pty,icanon=0,cfmakeraw,stderr,sighup,sigint,sigquit
