#!/bin/sh

K_UPSTREAM="%KERNEL_UPSTREAM%"
K_ABINAME="%KERNEL_ABINAME%"

VER="${K_UPSTREAM}-${K_ABINAME}"

if [ "$(id -u)" -ne 0 ]; then
	[ -x "$(which su-to-root)" ] && exec su-to-root -c "$0"
	printf "ERROR: $0 needs root capabilities, please start it as root.\n\n" >&2
	exit 1
fi

if [ -e "/boot/vmlinuz-${VER}" ]; then
	echo "ERROR: /boot/vmlinuz-${VER} already exist, terminate abnormally" >&2
	exit 2
fi

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
INSTALL_DEP=
[ -x /usr/bin/gcc-4.2 ]           || INSTALL_DEP="$INSTALL_DEP gcc-4.2"
[ -x /usr/sbin/update-initramfs ] || INSTALL_DEP="$INSTALL_DEP initramfs-tools"

# take care to install b43-fwcutter, if bcm43xx-fwcutter is already installed
if dpkg -l bcm43xx-fwcutter 2>/dev/null | grep -q '^[hi]i' || [ -e /lib/firmware/bcm43xx_pcm4.fw ]; then
	dpkg -l b43-fwcutter 2>/dev/null | grep -q '^[hi]i' || INSTALL_DEP="$INSTALL_DEP b43-fwcutter"
fi

# make sure udev-config-sidux is up to date
# - do not blacklist b43, we need it for kernel >= 2.6.23
# - make sure to install the IEEE1394 vs. FireWire "Juju" blacklist
if [ -r /etc/modprobe.d/sidux ] || [ -r /etc/modprobe.d/ieee1394 ] || [ -r /etc/modprobe.d/mac80211 ]; then
	VERSION=$(dpkg -l udev-config-sidux 2>/dev/null | awk '/^[hi]i/{print $3}')
	dpkg --compare-versions ${VERSION:-0} lt 0.4.3
	if [ "$?" -eq 0 ]; then
		INSTALL_DEP="$INSTALL_DEP udev-config-sidux"
	fi
else
	INSTALL_DEP="$INSTALL_DEP udev-config-sidux"
fi

# check resume partition configuration is valid
if [ -x /usr/sbin/get-resume-partition ]; then
	VERSION=$(dpkg -l sidux-scripts 2>/dev/null | awk '/^[hi]i/{print $3}')
	dpkg --compare-versions ${VERSION:-0} ge 0.1.38
	if [ "$?" -eq 0 ]; then
		get-resume-partition
	fi
fi

# add linux-image and linux-headers to the install lists
INSTALL_DEP="linux-image-${VER} linux-headers-${VER} $INSTALL_DEP"

# install kernel, headers, documentation and any extras that were detected
if [ -n "$INSTALL_DEP" ]; then
	apt-get update
	apt-get --assume-yes install $INSTALL_DEP
fi

# something went wrong, allow apt an attempt to fix it
if [ "$?" -ne 0 ]; then
	if [ -e "/boot/vmlinuz-${VER}" ]; then 
		apt-get --fix-broken install
	else
		[ -x /usr/sbin/update-grub ] && update-grub
		echo "kernel image not install, terminate abnormally!"
		exit 3
	fi

fi

[ -L /boot/vmlinuz ] &&	ln -fs "vmlinuz-${VER}" /boot/vmlinuz
[ -L /vmlinuz ] &&	ln -fs "boot/vmlinuz-${VER}" /vmlinuz

# we do need an initrd
if [ ! -f "/boot/initrd.img-${VER}" ]; then
	update-initramfs -k "${VER}" -c
fi

# set new kernel as default
[ -L /boot/initrd.img ] &&	ln -fs "initrd.img-${VER}" /boot/initrd.img
[ -L /initrd.img ] &&		ln -fs "boot/initrd.img-${VER}" /initrd.img
[ -L /boot/System.map ] &&	ln -fs "System.map-${VER}" /boot/System.map

# in case we just created an initrd, update menu.lst
if [ -x /usr/sbin/update-grub ]; then
	update-grub
fi

# set symlinks to the kernel headers
ln -fs "linux-headers-${VER}" /usr/src/linux >/dev/null 2>&1

# try to install external dfsg-free module packages
for i in acer_acpi acerhk acx atl2 aufs et131x fsam7400 gspca kqemu sqlzma ndiswrapper omnibook quickcam av5100 squashfs vboxadd vboxdrv; do
	MODULE_PATH="$(/sbin/modinfo -k $(uname -r) -F filename "${i}" 2>/dev/null)"
	if [ -n "${MODULE_PATH}" ]; then
		MODULE_PACKAGE="$(dpkg -S ${MODULE_PATH} 2>/dev/null)"
		if [ -n "${MODULE_PACKAGE}" ]; then
			MODULE_PACKAGE="$(echo ${MODULE_PACKAGE} | sed s/$(uname -r).*/${VER}/g)"
			if grep-aptavail -PX "${MODULE_PACKAGE}" >/dev/null 2>&1; then
				apt-get --assume-yes install "${MODULE_PACKAGE}"
				if [ "$?" -ne 0 ]; then
					apt-get --fix-broken install
				else
					# ignore error cases for now, apt will do the "right" thing to get 
					# into a consistent state and worst that could happen is some external
					# module not getting installed
					:
				fi
			fi
		fi
	fi
done

# hints for madwifi
if /sbin/modinfo -k $(uname -r) -F filename ath_pci >/dev/null 2>&1; then
	if [ -f /usr/src/madwifi.tar.bz2 ] && which m-a >/dev/null; then
		# user setup madwifi with module-assistant already
		# we may as well do that for him again now
		if [ -d /usr/src/modules/madwifi/ ]; then
			rm -rf /usr/src/modules/madwifi/
		fi

		m-a --text-mode --non-inter -l "${VER}" a-i madwifi
	else
		echo
		echo "Atheros Wireless Network Adaptor will not work until"
		echo "the non-free madwifi driver is reinstalled."
		echo
	fi
fi

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

