# day 1

Continuing what I left when ESLs didn't sell, for fun and without any obligation to progress.

Base station comes with linux openwrt 3.10.14, running on mt7621 processor, 256 MB ram, and entire
system is packed in 32MB of flash ( winbond ws25Q256jv chip ). 

The goal of this entire project is to understand and reverse engineer the BLE communication with
end devices ( ESL screens ).

Entire CPU, mem and flash come as a unified module HLK-7621. I ordered three of those, as they are very useful modules for general network applications ( and a board I broke during the process ) 

Other than the computer board, there is 1 to 4 usb hub, and 4 usb ports are connected to usb-serial chips which then communicate with goodix gr551 chips which are BLE transcievers. 

The original flash image was extracted using esp directly connected to the SPI flash chip. At first 
I desoldered the chip, but later I found out we can read/write spi directly while in circuit if we
have the CPU power on reset active, so there is no need to solder/desolder it again.

Other than this some relative goal for this is to build a custom image with up to date kernel image and also up to date bootloader + write our own simple software for esls tag management. 

The BLE transciever chips also have arm cortex m4f, the code for which ( or part of the code ) is sideloaded by the app that runs on the base station. 

First goal is to understand the communication between the app and the transcievers ( also to decipher the code that is run when we get ESLs update from the server ). 

Interface for creating ESLS template allows for couple of objects to be added, like text, rects, images, barcodes and alike. What I'm wondering is are they sending entire image to the display devices ( they are low res really, but again ) or they are just sending the meta structure of the image and then rendering it localy.

Anyways, for now, I have 1 esp32s3 acting as esp-usb-bridge ( which gives me serial and jtag/swd interface over usb ). Previously I've written my own serial forward program and luckily I don't need it any more cause I've had to reprogram every time I needed different baud rate. This device gives me a root shell to the linux running on base station device, and that's it. We go from there ( though much of the other work has been dine before, I've decided to reboot since I don't remember those things anymore ) 

# day 2

Added original flash content to this repo. 

Extracting original firmware using `binwalk -eM -C unpacked original_img.bin`

So after that in `unpacked` dir, there we have some files of interest: `mqtt_client`, `firmware_download`, `hd_slave.bin`, all of which are located in `_original_img.bin.extracted/squashfs-root/usr/sbin` .

The mqtt_client is the main process that is running on the base station.

One of the first things I want to do is intercept serial communication between ble devices and the main program, that way
I can track what is going on when I update price tag on the server. 

The way I plan to do it is with socat, creating virtual serial port and modifying the mqtt_client binary to open different port (the virtual one) and than logging the communication to a file. I will try with statically linked socat built for mipsel arch.

There is wget installed on base station, but it doesn't support HTTP, so I first downloaded the file onto my computer and than used serve to serve it from my computer for the base station. 

The socat binary I'm using is `https://github.com/hypn/misc-binaries/blob/master/socat-mipsel32-static-debian-squeeze` ( thx ) 

So what I've done is changed all references to `/dev/ttyUSB` to `/dev/ttyDEV` in the binary, assembled it and transfered it to device now using scp. I've had to kill the zk_ap_keep_running script which would check if the mqtt_client stopped working, now I'm going to start the socat and log a communication to a file.

Every time mqtt_client start, it restarts the usb hub as it seems ( since serial devices are enumerated again ), but the good thing is it waits/retries opening file descriptors when loading what it calls 'firmware' for the ble chips. It gives us the opportunity to start sockat later.

I have two terminal connected over ssh to the devices, and my pc on the same network. Because the amount of logging is huge, I've noticed that if I try to log to on-device file, it causes device to reboot ( don't know why ).

So what I've decided to do is to as I said, start mqtt_client first ( in the shell provided by the serial port connection ). And than on 1 of the terminals stream the sockat output over ssh to my computer, and in other terminal run 3 other sockat processes to virtualise other 3 ports ( but we don't really care about logging these for now ) 


So : 

```
Terminal 1:

root@OpenWrt:/# ./socat-mipsel32-static-debian-squeeze -d -d -x /dev/ttyUSB0,rawer,b1000000,unlink-close=
0,nonblock,ignoreeof pty,link=/dev/ttyDEV0,rawer 2>&1 | ssh m5m6@192.168.1.17 cat \> log_0.txt 

Terminal 2:

root@OpenWrt:/# ./socat-mipsel32-static-debian-squeeze -x /dev/ttyUSB1,rawer,b1000000,unlink-close=0,nonb
lock,ignoreeof pty,link=/dev/ttyDEV1,rawer 1>/dev/null 2>&1 &
root@OpenWrt:/# ./socat-mipsel32-static-debian-squeeze -x /dev/ttyUSB2,rawer,b1000000,unlink-close=0,nonb
lock,ignoreeof pty,link=/dev/ttyDEV2,rawer 1>/dev/null 2>&1 &
root@OpenWrt:/# ./socat-mipsel32-static-debian-squeeze -x /dev/ttyUSB3,rawer,b1000000,unlink-close=0,nonb
lock,ignoreeof pty,link=/dev/ttyDEV3,rawer 1>/dev/null 2>&1 &


```

The log of that will be in repository as : `log_22_11_2026.log`


For that I'd conclude this day, I'll try to analyze the output some other day, actually these logs are just firmware load and than some communication not related to updating displays themselves.





