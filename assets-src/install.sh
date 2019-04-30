#!/system/bin/sh

./r3 install.sh

ln -sf / root
ln -sf /storage .
ln -sf /mnt .
ln -sf /sdcard .
mv r3 system
rm install.*
exit
################
REBOL[]
unzip %./ %install.zip

