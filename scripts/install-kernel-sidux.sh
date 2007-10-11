#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
	[ -x /usr/bin/su-me ] && DISPLAY="" exec su-me "$0" "$@"

	echo Error: You must be root to run this script!
	exit 1
fi

VER=%KERNEL_VERSION%
SUB=1
ALSA=
ARCH="$(dpkg-architecture -qDEB_BUILD_ARCH)"

rm -f	/boot/System.map \
	/boot/vmlinuz \
	/boot/initrd.img \
	/etc/initramfs-tools/conf.d/resume

# fix /etc/kernel-img.conf
sed -i	-e "s/\(postinst_hook\).*/\1\ \=\ \\/usr\\/sbin\\/update-grub/" \
	-e "s/\(postrm_hook\).*/\1\ \=\ \\/usr\\/sbin\\/update-grub/" \
	-e "s/\(do_initrd\).*/\1\ \=\ Yes/" \
	-e "/ramdisk.*mkinitrd\\.yaird/d" \
		/etc/kernel-img.conf

grep -q do_initrd /etc/kernel-img.conf 2> /dev/null || \
	echo "do_initrd = Yes" >> /etc/kernel-img.conf


# install important dependencies
[ -x /usr/bin/gcc-4.2 ]		|| INSTALL_DEP="$INSTALL_DEP gcc-4.2"
[ -x /usr/sbin/mkinitramfs ]	|| INSTALL_DEP="$INSTALL_DEP initramfs-tools"

# take care to install b43-fwcutter, if bcm43xx-fwcutter is already installed
if dpkg -l bcm43xx-fwcutter >/dev/null 2>&1 || test -r /lib/firmware/bcm43xx_pcm4.fw; then
	INSTALL_DEP="$INSTALL_DEP b43-fwcutter"
fi

# do not blacklist b43, we need it for kernel >= 2.6.23
if [ -r /etc/modprobe.d/mac80211 ] && dpkg --compare-versions $(dpkg -l udev-config-sidux >/dev/null 2>&1 | awk '/^ii/{print $3}') lt 0.4.2 >/dev/null 2>&1; then
	INSTALL_DEP="$INSTALL_DEP udev-config-sidux"
fi

if [ -n "$INSTALL_DEP" ]; then
	apt-get update
	apt-get install $INSTALL_DEP
fi

# install kernel, headers and our patches to the vanilla tree
dpkg -i "linux-image-${VER}_${SUB}_${ARCH}.deb"
dpkg -i "linux-headers-${VER}_${SUB}_${ARCH}.deb"
dpkg -i "linux-doc-${VER}_${SUB}_all.deb"
[ -n "$ALSA" ] && dpkg -i "alsa-modules-${VER}_${ALSA}+${SUB}_${ARCH}.deb"
[ -f "linux-custom-patches-${VER}_${SUB}_${ARCH}.deb" ] && dpkg -i "linux-custom-patches-${VER}_${SUB}_${ARCH}.deb"

ln -fs "vmlinuz-${VER}"		/boot/vmlinuz
ln -fs "boot/vmlinuz-${VER}"	/vmlinuz

# we do need an initrd
if [ ! -r "/boot/initrd.img-${VER}" ]; then
	mkinitramfs -o "/boot/initrd.img-${VER}" "${VER}"
fi

# set new kernel as default
ln -fs "initrd.img-${VER}"	/boot/initrd.img
ln -fs "boot/initrd.img-${VER}"	/initrd.img
ln -fs "System.map-${VER}"	/boot/System.map

# in case we just created an initrd, update menu.lst
update-grub

# set symlinks to the kernel headers
rm -f "/lib/modules/${VER}/build" >/dev/null 2>&1
ln -s "/usr/src/linux-headers-${VER}" "/lib/modules/${VER}/build"
ln -fs "linux-headers-${VER}" /usr/src/linux >/dev/null 2>&1

# remove agpgart, fglrx, radeon modules
sed -i	-e "/^[\ \t]\?agpgart/d" \
	-e "/^[\ \t]\?fglrx/d" \
	-e "/^[\ \t]\?radeon/d" \
		/etc/modules

# hints for fglrx
if grep -q '"fglrx"' /etc/X11/xorg.conf; then
	echo "ATI RADEON 3D acceleration will NOT work with the new kernel until"
	echo "the non-free fglrx driver is reinstalled."
	echo
fi

# workaround for nvidia
if grep -q '"nvidia"' /etc/X11/xorg.conf; then
	sed -i "s/^\([\ \t]\?Driver.*\)\"nvidia\"/\1\"nv\"/g" /etc/X11/xorg.conf
	echo "non-free nVidia driver has been DISABLED!"
	echo
fi

# alsa sound hack
rm -f /var/lib/alsa/asound.state
echo alsa sound will be muted next start.
echo use "alsactl store" as root to save it after checking the volumes.

# grub notice
echo 'Now you can simply reboot when using GRUB (default). In case you use'
echo 'LILO you have to do the mentioned changes manually.'
echo ""
echo "Make sure that /etc/fstab and /boot/grub/menu.lst use UUID- or LABEL-"
echo "based mounting, which is required for classic IDE vs. lib(p)ata changes!"

echo Have fun!

