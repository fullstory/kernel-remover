#!/bin/sh
KERNEL=%KERNEL_VERSION%
apt-get remove --purge $(COLUMNS=200 dpkg -l|awk '{print $2}'|grep $KERNEL)
rm -rf /lib/modules/$KERNEL
rm -rf /usr/src/kernel-headers-$KERNEL
rm -rf /usr/src/linux-headers-$KERNEL
rm -rf /usr/src/linux-$KERNEL
[ -r /boot/grub/menu.lst -a -x /usr/sbin/update-grub ] && /usr/sbin/update-grub
