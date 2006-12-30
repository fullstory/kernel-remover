#!/bin/sh

KERNEL=%KERNEL_VERSION%

apt-get remove --purge $(COLUMNS=200 dpkg -l | awk '{print $2}' | grep "$KERNEL")

rm -rf	"/lib/modules/$KERNEL" \
	"/usr/src/kernel-headers-$KERNEL" \
	"/usr/src/linux-headers-$KERNEL" \
	"/usr/src/linux-$KERNEL"

[ -r /boot/grub/menu.lst ] && [ -x /usr/sbin/update-grub ] && /usr/sbin/update-grub

