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

