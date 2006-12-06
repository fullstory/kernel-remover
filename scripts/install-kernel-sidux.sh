#!/bin/sh

if [ $(id -u) != 0 ]; then
	echo Error: You must be root to run this script!
	exit 1
fi

VER=%KERNEL_VERSION%
SUB=1
ALSA=

rm -f	/boot/System.map \
	/boot/vmlinuz \
	initrd.img

grep -q '  */sbin/update-grub$' /etc/kernel-img.conf 2> /dev/null && sed -i 's%=.*sbin/update-grub%= update-grub%' /etc/kernel-img.conf 2> /dev/null

dpkg -i linux-image-"$VER"_"$SUB"_$(dpkg-architecture -qDEB_BUILD_ARCH).deb
dpkg -i linux-headers-"$VER"_"$SUB"_$(dpkg-architecture -qDEB_BUILD_ARCH).deb
dpkg -i linux-doc-"$VER"_"$SUB"_all.deb
test -n "$ALSA" && dpkg -i alsa-modules-"$VER"_"$ALSA"+"$SUB"_$(dpkg-architecture -qDEB_BUILD_ARCH).deb
test -f linux-custom-patches-"$VER"_"$SUB"_$(dpkg-architecture -qDEB_BUILD_ARCH).deb && dpkg -i linux-custom-patches-"$VER"_"$SUB"_$(dpkg-architecture -qDEB_BUILD_ARCH).deb

#ln -sf System.map-$VER /boot/System.map
#ln -sf vmlinuz-$VER /boot/vmlinuz

[ -x /usr/sbin/yaird ] || apt-get install yaird
mkinitrd.yaird -o /boot/initrd.img-$VER $VER
if [ -e /boot/initrd.img-$VER ]; then
	#ln -sf initrd.img-$VER /boot/initrd.img
	update-grub
fi

# install important dependencies
[ -x /usr/bin/gcc-4.1 ] || apt-get install gcc-4.1
dpkg -l module-init-tools &>/dev/null || apt-get -y install module-init-tools
update-rc.d module-init-tools start 20 S . >/dev/null

rm -rf /usr/src/linux /usr/src/linux-$VER /lib/modules/$VER/build
if [ ! -d /usr/src/linux-headers-$VER/scripts ]; then
	rm -f /usr/src/linux-headers-$VER/scripts
fi

ln -s linux-headers-$VER /usr/src/linux-$VER
ln -s /usr/src/linux-$VER /lib/modules/$VER/build  
cp -f /boot/config-$VER /usr/src/linux-$VER/.config
rm -rf /usr/src/linux-$VER/Documentation
ln -s /usr/share/doc/linux-doc-$VER/Documentation /usr/src/linux-$VER/Documentation
ln -sf boot/vmlinuz-$VER /vmlinuz

# remove agpgart, fglrx, radeon modules
perl -pi -e 's/^agpgart\n?//' /etc/modules
perl -pi -e 's/^fglrx\n?//' /etc/modules
perl -pi -e 's/^radeon\n?//' /etc/modules

# hack for new installer
X_CONF=XF86Config-4
if which Xorg >/dev/null; then
	[ -e /etc/X11/xorg.conf ] && X_CONF=xorg.conf
fi

# hints for fglrx
if grep -q '"fglrx"' "/etc/X11/$X_CONF"; then
	echo "ATI RADEON 3D acceleraction will NOT work with the new kernel until"
	echo "the driver is reinstalled."
	echo
fi

# workaround for nvidia
if grep -q '"nvidia"' /etc/X11/$X_CONF; then
	perl -pi -e 's/^([\s]*Driver\s*)"nvidia"/\1"nv"/g' "/etc/X11/$X_CONF"
	grep -q ^nvidia /etc/modules || echo nvidia >> /etc/modules
	echo "NVIDIA driver has been DISABLED!"
	echo
fi

# eepro100 fix
sed -i s/eepro100/e100/ /etc/modules

# psmouse fix
grep -q ^psmouse /etc/modules || echo psmouse >> /etc/modules

# fix modules
rm -f /etc/modules-*

# mouse fix
perl -pi -e 's|(\s*Option\s+"Protocol"\s+)"auto"|\1"IMPS/2|' "/etc/X11/$X_CONF"
[ -f "/etc/X11/$X_CONF.1st" ] && perl -pi -e 's|(\s*Option\s+"Protocol"\s+)"auto"|\1"IMPS/2"|' "/etc/X11/$X_CONF.1st"
echo 'Notice: the mouse protocol "auto" has been changed to "IMPS/2"!'
echo 'If you have problems change it to "PS/2" - "auto" does not work with 2.6.'
echo "Change was done in /etc/X11/$X_CONF (and /etc/X11/$X_CONF.1st)."
echo

# change usbdevfs to usbfs with lowered right setting
perl -pi -e "s|.*/proc/bus/usb.*|usbfs  /proc/bus/usb  usbfs  devmode=0666  0  0|" /etc/fstab
echo usbdevfs has been replaced by usbfs in /etc/fstab with devmode=0666

# camera group hack
USER=$(grep 1000 /etc/passwd|cut -f1 -d:)
GROUP=$(echo $(groups $USER|cut -f2 -d:)|sed "s/ /,/g")
echo $GROUP|grep -q camera || (
[ "$USER" ] &&  usermod -G $GROUP,camera $USER
)

# alsa sound hack
rm -f /var/lib/alsa/asound.state
echo alsa sound will be muted next start.
echo use "alsactl store" as root to save it after checking the volumes.

# grub notice
echo 'Now you can simply reboot when using GRUB (default). In case you use'
echo 'LILO you have to do the mentioned changes manually.'
echo Have fun!

