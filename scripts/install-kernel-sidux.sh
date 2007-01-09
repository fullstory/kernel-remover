#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
	[ -x /usr/bin/su-me ] && DISPLAY="" exec su-me "$0" "$@"

	echo Error: You must be root to run this script!
	exit 1
fi

VER=%KERNEL_VERSION%
SUB=1
ALSA=
X_CONF="/etc/X11/xorg.conf"

rm -f	/boot/System.map \
	/boot/vmlinuz \
	initrd.img

# fix /etc/kernel-img.conf
sed -i	-e s/postinst_hook.*/postinst_hook\ \=\ \\/usr\\/sbin\\/update-grub/ \
	-e s/postrm_hook.*/postrm_hook\ \=\ \\/usr\\/sbin\\/update-grub/ \
	-e s/do_initrd.*/do_initrd\ \=\ Yes/ \
	-e /ramdisk.*mkinitrd\\.yaird/d \
		/etc/kernel-img.conf
grep -q do_initrd /etc/kernel-img.conf 2> /dev/null || \
	echo "do_initrd = Yes" >> /etc/kernel-img.conf


# install important dependencies
[ -x /usr/bin/gcc-4.1 ]		|| apt-get install gcc-4.1
[ -x /usr/sbin/mkinitramfs ]	|| apt-get install initramfs-tools
if [ ! -x /usr/sbin/scanpartitions] || dpkg --compare-versions "$(dpkg -l | awk '/^ii\ \ scanpartitions[[:space:]]/{ print $3 }')" lt "0.7.3"; then
	if dpkg --compare-versions "$(LANG= apt-cache policy scanpartitions | awk '/^\ \ Candidate\:/{print $2}')" lt "0.7.3"; then
		apt-get update
	fi
	apt-get install scanpartitions
fi

## DEBUGGING-ONLY!
exit 666

# convert fstab to uuid/ labels, this is mandatory for libata
if grep -q ^\\/dev\\/[hs]d[a-z][1-9][0-9]\\?[[:space:]] /etc/fstab; then
	BACKUP="$(mktemp -p /etc/ fstab.XXXXXXXXXX)"
	cat /etc/fstab > "$BACKUP"

	for i in $(awk '/^\/dev\/[hs]d[a-z][1-9][0-9]?[[:space:]]/{print $1}' /etc/fstab); do
		TMP="$(/lib/udev/vol_id -u $i)"
		if [ -n "$TMP" ]; then
			sed -i "s%^${i}[[:space:]]%${TMP}\t%" /etc/fstab
		else
			# XXX:	comment out this fstab line, we're talking about
			#	removable media which isn't currently attached and
			#	will lead to namespace collisions!
			echo "FIXME: comment out not attached removable media!"
		fi

		MESSAGE="Your /etc/fstab was changed to allow mount by-uuid, this change is necessary
to allow libata vs. IDE switches in this and newer kernels.
A backup of your old fstab has been saved under $BACKUP."
done
fi

# convert /boot/grub/menu.lst
# XXX:	we need to move root=... in /boot/grub/menu.lst to root=UUID=..., only
#	change old school entries (/dev/hda1, /dev/sda1) for our / partition, 
#	don't touch / for other partitions/ distributions, those might now 
#	allow boot by-uuid, perhaps because they're initrd-less or still use 
#	yaird. /proc/cmdline is not reliable, think of chroot systems and bind
#	mounted procfs.
ROOT_PARTITION="$(grep -v ^[[:space:]]\\?\# /etc/fstab | cut -d\# -f1 | grep [[:space:]]\\/[[:space:]] | awk '{print $1}')"
case $ROOT_PARTITION in
	LABEL\=*)
		ROOT_PARTITION="$(readlink /dev/disk/by-label/`echo $ROOT_PARTITION | cut -d\= -f2` | sed s/.*\\//\\/dev\\//)"
		;;
	UUID\=*)
		ROOT_PARTITION="$(readlink /dev/disk/by-uuid/`echo $ROOT_PARTITION | cut -d\= -f2` | sed s/.*\\//\\/dev\\//)"
		;;
	\\/dev\\/[hs]d[a-z][1-9][0-9]\\?)
		ROOT_PARTITION="$ROOT_PARTITION"
		;;
	*)
		echo "ERROR: can't determine / partition for grub, take care to adapt /boot/grub/menu.lst on your own"
		exit 999
		;;
esac

if grep -q root\=\\/dev\\/[hs]d[a-z][1-9][0-9]\\? /boot/grub/menu.lst; then
	BACKUP="$(mktemp -p /boot/grub/ menu.lst.XXXXXXXXXX)"
	cat /boot/grub/menu.lst > "$BACKUP"
	
	sed -i "s%root\=$ROOT_PARTITION%root\=UUID\=$(/lib/udev/vol_id -u $ROOT_PARTITION)%" /boot/grub/menu.lst

	MESSAGE="$MESSAGE

Your /boot/grub/menu.lst was changed to identify / by-uuid, this change is 
necessary to allow libata vs. IDE switches in this and newer kernels.
A backup of your old fstab has been saved under $BACKUP."
fi

# install kernel, headers and our patches to the vanilla tree
dpkg -i linux-image-"$VER"_"$SUB"_$(dpkg-architecture -qDEB_BUILD_ARCH).deb
dpkg -i linux-headers-"$VER"_"$SUB"_$(dpkg-architecture -qDEB_BUILD_ARCH).deb
dpkg -i linux-doc-"$VER"_"$SUB"_all.deb
test -n "$ALSA" && dpkg -i alsa-modules-"$VER"_"$ALSA"+"$SUB"_$(dpkg-architecture -qDEB_BUILD_ARCH).deb
test -f linux-custom-patches-"$VER"_"$SUB"_$(dpkg-architecture -qDEB_BUILD_ARCH).deb && dpkg -i linux-custom-patches-"$VER"_"$SUB"_$(dpkg-architecture -qDEB_BUILD_ARCH).deb

ln -fs "vmlinuz-$VER"		/boot/vmlinuz
ln -fs "boot/vmlinuz-$VER"	/vmlinuz

# we do need an initrd
if [ ! -r "/boot/initrd.img-$VER" ]; then
	mkinitramfs -o "/boot/initrd.img-$VER" "$VER"
fi
ln -fs "initrd.img-$VER"	/boot/initrd.img
ln -fs "boot/initrd.img-$VER"	/initrd.img

ln -fs "System.map-$VER"	/boot/System.map

# in case we just created an initrd, update menu.lst
update-grub

# set symlinks to the kernel headers
rm -f "/lib/modules/$VER/build" >/dev/null 2>&1
ln -s "/usr/src/linux-headers-$VER" "/lib/modules/$VER/build"
ln -fs "linux-headers-$VER" /usr/src/linux >/dev/null 2>&1

# remove agpgart, fglrx, radeon modules
perl -pi -e 's/^agpgart\n?//'	/etc/modules
perl -pi -e 's/^fglrx\n?//'	/etc/modules
perl -pi -e 's/^radeon\n?//'	/etc/modules

# hints for fglrx
if grep -q '"fglrx"' "$X_CONF"; then
	echo "ATI RADEON 3D acceleraction will NOT work with the new kernel until"
	echo "the driver is reinstalled."
	echo
fi

# workaround for nvidia
if grep -q '"nvidia"' "$X_CONF"; then
	perl -pi -e 's/^([\s]*Driver\s*)"nvidia"/\1"nv"/g' "$X_CONF"
	grep -q ^nvidia /etc/modules || echo nvidia >> /etc/modules
	echo "NVIDIA driver has been DISABLED!"
	echo
fi

# alsa sound hack
rm -f /var/lib/alsa/asound.state
echo alsa sound will be muted next start.
echo use "alsactl store" as root to save it after checking the volumes.

# grub notice
echo 'Now you can simply reboot when using GRUB (default). In case you use'
echo 'LILO you have to do the mentioned changes manually.'

echo "$MESSAGE"

echo Have fun!

