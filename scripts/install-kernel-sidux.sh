#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
	[ -x /usr/bin/su-me ] && DISPLAY="" exec su-me "$0" "$@"

	echo Error: You must be root to run this script!
	exit 1
fi

VER=%KERNEL_VERSION%
SUB=1
ARCH="$(dpkg-architecture -qDEB_BUILD_ARCH)"

rm -f	/boot/System.map \
	/boot/vmlinuz \
	/boot/initrd.img

# ensure /etc/kernel-img.conf is configured with correct settings
# - fix path to update-grub
# - make sure "do_initrd = Yes"
if [ -w /etc/kernel-img.conf ]; then
	echo -n "Checking /etc/kernel-img.conf..."

	sed -i	-e "s/\(postinst_hook\).*/\1\ \=\ \\/usr\\/sbin\\/update-grub/" \
		-e "s/\(postrm_hook\).*/\1\ \=\ \\/usr\\/sbin\\/update-grub/" \
		-e "s/\(do_initrd\).*/\1\ \=\ Yes/" \
		-e "/ramdisk.*mkinitrd\\.yaird/d" \
			/etc/kernel-img.conf
	
	if ! grep -q do_initrd /etc/kernel-img.conf; then
		echo "do_initrd = Yes" >> /etc/kernel-img.conf
	fi

	echo "done."
else
	echo "WARNING: /etc/kernel-img.conf is missing, creating file with defaults..."
	cat > /etc/kernel-img.conf <<EOF
do_bootloader = No
postinst_hook = /usr/sbin/update-grub
postrm_hook   = /usr/sbin/update-grub
do_initrd     = Yes
EOF
fi

# install important dependencies before attempting to install kernel
unset INSTALL_DEP
[ -x /usr/bin/gcc-4.2 ]           || INSTALL_DEP="$INSTALL_DEP gcc-4.2"
[ -x /usr/sbin/update-initramfs ] || INSTALL_DEP="$INSTALL_DEP initramfs-tools"

# take care to install b43-fwcutter, if bcm43xx-fwcutter is already installed
if dpkg -l bcm43xx-fwcutter 2>/dev/null | grep -q '^[hi]i' || [ -e /lib/firmware/bcm43xx_pcm4.fw ]; then
	INSTALL_DEP="$INSTALL_DEP b43-fwcutter"
fi

# make sure udev-config-sidux is up to date
# - do not blacklist b43, we need it for kernel >= 2.6.23
# - make sure to install the IEEE1394 vs. FireWire "Juju" blacklist
if [ -r /etc/modprobe.d/sidux ] || [ -r /etc/modprobe.d/ieee1394 ] || [ -r /etc/modprobe.d/mac80211 ]; then
	dpkg --compare-versions $(dpkg -l udev-config-sidux >/dev/null 2>&1 | awk '/^[hi]i/{print $3}') lt 0.4.3 >/dev/null 2>&1
	if [ "$?" -eq 0 ]; then
		INSTALL_DEP="$INSTALL_DEP udev-config-sidux"
	fi
else
	INSTALL_DEP="$INSTALL_DEP udev-config-sidux"
fi

if [ -n "$INSTALL_DEP" ]; then
	apt-get update
	apt-get install $INSTALL_DEP
fi

# check resume partition configuration is valid
if [ -x /usr/sbin/get-resume-partition ]; then
	dpkg --compare-versions $(dpkg -l sidux-scripts >/dev/null 2>&1 | awk '/^[hi]i/{print $3}') ge 0.1.38 >/dev/null 2>&1
	if [ "$?" -eq 0 ]; then
		get-resume-partition
	fi
fi

# externally supplied modules, check to see if currently in use
unset EXTRA_DEBS
for deb in *-${VER}_*+${SUB}_${ARCH}.deb; do
	[ -f "$deb" ] || continue
	
	for mod in $(dpkg --contents $deb | sed -n -e 's%-%_%g;s%.*/\([^\.]\+\)\.ko$%\1%p'); do
		[ -n "$mod" ] || continue
		
		if [ -d "/sys/module/$mod" ] || grep -w -q "^$mod" /proc/modules; then
			if [ "$mod" = vboxdrv ]; then
				# we cannot determine reliably if its free or non-free
				# innotek, please get a clue!
				[ -d /usr/share/doc/virtualbox-ose ] || break
			fi
			
			# module contained within this package is currently in use
			EXTRA_DEBS="$EXTRA_DEBS $deb"
			break
		fi
	done
done

# our patches to the vanilla tree
if [ -f "linux-custom-patches-${VER}_${SUB}_${ARCH}.deb" ]; then
	EXTRA_DEBS="$EXTRA_DEBS linux-custom-patches-${VER}_${SUB}_${ARCH}.deb"
fi

# install kernel, headers, documentation and any extras that were detected
dpkg -i "linux-image-${VER}_${SUB}_${ARCH}.deb" \
	"linux-headers-${VER}_${SUB}_${ARCH}.deb" \
	"linux-doc-${VER}_${SUB}_all.deb" \
	$EXTRA_DEBS

# something went wrong, allow apt an attempt to fix it
if [ "$?" -ne 0 ]; then
	apt-get --fix-broken install
fi

ln -fs "vmlinuz-${VER}"		/boot/vmlinuz
ln -fs "boot/vmlinuz-${VER}"	/vmlinuz

# we do need an initrd
if [ ! -f "/boot/initrd.img-${VER}" ]; then
	update-initramfs -k "${VER}" -c
fi

# set new kernel as default
ln -fs "initrd.img-${VER}"	/boot/initrd.img
ln -fs "boot/initrd.img-${VER}"	/initrd.img
ln -fs "System.map-${VER}"	/boot/System.map

# in case we just created an initrd, update menu.lst
if [ -x /usr/sbin/update-grub ]; then
	update-grub
fi

# set symlinks to the kernel headers
rm -f "/lib/modules/${VER}/build" >/dev/null 2>&1
ln -s "/usr/src/linux-headers-${VER}" "/lib/modules/${VER}/build"
ln -fs "linux-headers-${VER}" /usr/src/linux >/dev/null 2>&1

# hints for fglrx
if grep -q '"fglrx"' /etc/X11/xorg.conf; then
	echo
	echo "ATI RADEON 3D acceleration will NOT work with the new kernel until"
	echo "the non-free fglrx driver is reinstalled."
	echo
fi

# hints for nvidia
if grep -q '"nvidia"' /etc/X11/xorg.conf; then
	sed -i "s/^\([\ \t]\?Driver.*\)\"nvidia\"/\1\"nv\"/g" /etc/X11/xorg.conf
	echo
	echo "nVidia 3D acceleration will NOT work with the new kernel until"
	echo "the non-free nVidia driver is reinstalled."
	echo
fi

# hints for madwifi
if [ -d /sys/module/ath_pci ] || grep -q '^ath_pci' /proc/modules; then
	echo
	echo "Atheros Wireless Network Adaptor will not work until"
	echo "the non-free madwifi driver is reinstalled."
	echo
fi

# grub notice
echo
echo "Now you can simply reboot when using GRUB (default). If you use the LILO"
echo "bootloader you will have to configure it to use the new kernel."
echo 
echo "Make sure that /etc/fstab and /boot/grub/menu.lst use UUID or LABEL"
echo "based mounting, which is required for classic IDE vs. lib(p)ata changes!"
echo
echo "For more details about UUID or LABEL fstab usage see the sidux manual:"
echo "   http://manual.sidux.com/en/part-cfdisk-en.htm#disknames"
echo
echo "Have fun!"
echo
