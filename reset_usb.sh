#/bin/sh

echo "1-2" | tee /sys/bus/usb/drivers/usb/unbind
echo "1-2" | tee /sys/bus/usb/drivers/usb/bind

