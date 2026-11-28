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

So just a bit more, we can see the ble device is sendinx `0x08 0x02` while waiting for firmware...

The first thing our program sends to device is as it seems firmware length ( file `hd_slave.bin` which can be found in extracted firmware is 93504 bytes long, when converted to hex `0x016d40` and the program send something very similar ( `01 40 6d` ) ( don't know why byte order is wrong at the beginning ), and after response from device (`06` ) the firmware is dumped byte for byte after which we get `cf` from device and `06` is again sent to device. From there on, we will continue.


# day 3

Ok, so we'll continue where we left of, now I'm also going to install mqtt proxy between the base station and the server ( it's not using tls so I'm going to be able to sniff raw trafic on that ). 

I'm going to use `https://github.com/VerSprite/zancudo` as interceptor proxy. 

To note: device auto restarts sometimes for some strange reason. 

Nothing to talk about right now, still struggling with streaming all the log files correctly. 
  
# day 4

So I created some helpers to get things easier, I'm not going to have more shells open as I can't really track what is going on. I created a host entry named `basestation` and I'm just 
gonna execute commands on remote machine like `ssh basestation sh < whateverfile.sh`.

Actually after some fiddleing around I will have a singe sh script to run everything and store logs where they need to be.  

I have further trimmed socat params ( sync can be probably removed to, but anyways )

I will have to mask log files for credentials.

What I have struggled with is transfering the logs of main application since they are neither pumped to stdout nor to stderr as it seems, and the solution was in front of my eyes all the time.
I'm now using socat to stream those logs also ( it creates a vitural terminal and execs the application ). 

So now we should be read to see some full logs and go from there.

To summerize todays work, I've created a simple run_all.sh script that is going to intercept all basestation comms, and also have logs of all the apps that are necessary to progress.

I added hooks to redact the phrases from the logs. Installing them using `./install_hooks.sh`

Some remarks based on issue raised by @Picard2000:
  - GAAT service UUID present in hd_slave.bin
  - concluded that more than 1 ( probably all munufacturers from china ) use same software ( zk_ap_keep_running -> Zkong? ) 
  - if they use the same software, are they interchangable? 
  - all goodix chipsets on these devices do have fused memory? do they crypt the comm? 


Other questions:
  - The firmware on tags runs as is. Why is firmware/part of it streamed for devices on AP?
  - MQTT communication is over http and seemingly username/password combinations of AP devices seem very low security, why not tls?

Since AP devices are not exposed, there is no inherent threat for objects, but security here was not first concern obviously.

# day 5

So today I'm going to try to analyze how the image is formed for the display, e.g. transmitter over network.

I've already been fiddling with it and first of a note regarding that. It seems the display is bound to transciver it connects to, so I'll have to monitor
all serial communication to see how the image is beeing transfered down the line.

I'm working with 2.9'' (black, white, red, yellow capable), with resolution 296x128 px.

I set device to single rectangle, yellow. If we assume resolution, we have 37_888 pixels in total,  which can have 4 colors, so 151552 bits in total to represent that without any compression,
which is 18994 bytes ( we get only 264 ). 

Than I added an empty textbox which yielded 264 bytes ( but content was not the same ). I have to write those files somehow if I'm gonna reference them, gonna do that today.

But when I added a `.` inside a textbox, content got to be 268 bytes. We can conclude it's packing screen content in some way. 

OK, I've modified zancudo a bit to store publish packets as bin files ( after topic has been decoded ) so I can diff them, can be found on my github (`MarkoMackic/zancudo`).

Also I've modified log storage to not overwrite anything existing for the date ( because I want every run to be available so I can reference it )

OK, so, to further reduce stuff, I'm going to just have some text on the screen ( text12341 ) on the yellow background, and I'm going to alter the last 5 to 1 and back to 5 and so on to see
what is different in what server sends to me.

I have captured 8 packets of data which we're going to analyze:

```
1. Packet identifier: 4172cab3-c646-4ba6-bde1-26d961fd906d, dataTotal: 560 - change to 1
2. Packet identifier: 73172ed2-2b15-45ec-9964-47f93bae2a5a, dataTotal: 564 - change to 5
3. Packet identifier: 928db118-f90f-4f91-add0-fdd58e427e23, dataTotal: 560 - change to 1
4. Packet identifier: 2248524a-7c05-4f0d-86e0-98b1606b9c4a, dataTotal: 560 - meta change, same content
5. Packet identifier: 108a5606-c12f-4365-a7f8-c0df60ca08b9, dataTotal: 564 - change to 5
6. Packet identifier: 8ebb4bda-3bfe-475a-b9f7-174677291e7a, dataTotal: 560 - change to 1
7. Packet identifier: 5210f2a7-ede7-4e95-8c94-7c81f104a186, dataTotal: 564 - change to 5
8. Packet identifier: c19fc70d-8486-4f72-8313-6bde660a0ff7, dataTotal: 560 - change to 1
```

I have added autocomplete for easier search of those files (`source autocomplete.sh`), should be corrected for absolute path, but it's fine for now.

From 3-4 I have changed some name in template, and not the actual value. 

OK, I'll store diffs to diffs with (xxx_xxx.diff), I'll first b64decode those packets, and
that is it for today.

The diffs are at `logs/28_11_2026/mqtt_packet_diffs`


