#!/bin/bash -e
#
# License: GPL2
#

# kernel.org mirror
MIRROR="http://kernel.org/pub/linux/kernel"
PATCH_MIRROR="http://sidux.com/files/patches"

# kernel version
REVISION="1"
#DEF_CPU="up"

# staging directory
if ((UID)); then
	# user
	SRCDIR=~/src
else
	# root
	SRCDIR=/usr/src
fi

# local config
if [[ -s ~/.kernel-sourcerc ]]; then
	source ~/.kernel-sourcerc
fi

KERNEL="latest-stable-${USER}-${DEF_CPU}-${REVISION}"

#%STATIC_VERSION%
[[ $STATIC_VERSION ]] && KERNEL="$STATIC_VERSION"

#=============================================================================#
#	kernel patch urls
#=============================================================================#
patches_for_kernel() {
	case "$1" in
		2.6.21*)
			PATCH+=( http://gaugusch.at/acpi-dsdt-initrd-patches/acpi-dsdt-initrd-v0.8.4-2.6.21.patch )
			PATCH+=( $PATCH_MIRROR/t-sinus_111card-2.6.16.diff )
			PATCH+=( $PATCH_MIRROR/2.6.21-at76_usb20070511.diff.bz2 )
			PATCH+=( $PATCH_MIRROR/unionfs-2.x-linux-2.6.21-u2.diff.gz )
			PATCH+=( $MIRROR/people/akpm/patches/2.6/2.6.21-rc6/2.6.21-rc6-mm1/broken-out/gregkh-driver-nozomi.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-zr364xx.diff.bz2 )
			PATCH+=( $PATCH_MIRROR/2.6.21_drivers-ata-ata_piix-postpone-pata.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_x86_64-silence-up-apic-errors.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_x86-dont-delete-cpu_devs-data.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_x86-fix-oprofile.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_x86-fsc-interrupt-controller-quirk.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_mpc52xx-sdma.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_mpc52xx-fec.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_input-kill-stupid-messages.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_kvm-19.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_mm-udf-fixes.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_sysfs-inode-allocator-oops.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_xfs-umount-fix.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_dvb-spinlock.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_i82875-edac-pci-setup.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_defaults-fat-utf8.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_defaults-unicode-vt.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_libata-hpa.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_libata-sata_nv-adma.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_libata-ali-atapi-dma.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_libata-sata_nv-wildcard-removal.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_libata-pata-pcmcia-new-ident.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_libata-pata-hpt3x2n-correct-revision-boundary.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_libata-pata-sis-fix-timing.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_wireless.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_git-wireless-dev.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_git-iwlwifi.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_mac80211-fixes.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_acpi-keep-tsc-stable-when-lapic-timer-c2-ok-is-set.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_clockevents-fix-resume-logic.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21-1.3194_acpi-dock-oops.patch )
			PATCH+=( $PATCH_MIRROR/2.6.21_ati-sb700.diff )
			PATCH+=( $PATCH_MIRROR/at76_usb-mac80211.diff )
			PATCH+=( $PATCH_MIRROR/zd1211rw-asus-2.6.21.diff )
			PATCH+=( $PATCH_MIRROR/2.6.21.4_futex.diff )
			;;
		2.6.22*)
			PATCH+=( http://gaugusch.at/acpi-dsdt-initrd-patches/acpi-dsdt-initrd-v0.8.4-2.6.21.patch )
			PATCH+=( $PATCH_MIRROR/t-sinus_111card-2.6.16.diff )
			PATCH+=( ftp://ftp.filesystems.org/pub/unionfs/unionfs-2.x/linux-2.6.22-rc6-u1.diff.gz )
			PATCH+=( $PATCH_MIRROR/2.6.22-at76_usb20070621.diff.bz2 )
			PATCH+=( $PATCH_MIRROR/2.6.22-1.3242_git-wireless-dev.patch.bz2 )
			PATCH+=( $PATCH_MIRROR/2.6.22-1.3242_defaults-fat-utf8.patch.bz2 )
			PATCH+=( $PATCH_MIRROR/2.6.22-1.3242_defaults-unicode-vt.patch.bz2 )
			PATCH+=( $PATCH_MIRROR/2.6.22-1.3242_input-kill-stupid-messages.patch.bz2 )
			PATCH+=( $MIRROR/people/akpm/patches/2.6/2.6.22-rc6/2.6.22-rc6-mm1/broken-out/git-ipwireless_cs.patch )
			PATCH+=( $MIRROR/people/akpm/patches/2.6/2.6.22-rc6/2.6.22-rc6-mm1/broken-out/gregkh-driver-nozomi.patch )
			PATCH+=( $MIRROR/people/akpm/patches/2.6/2.6.22-rc6/2.6.22-rc6-mm1/broken-out/fix-gregkh-driver-nozomi.patch )
			PATCH+=( $MIRROR/people/akpm/patches/2.6/2.6.22-rc6/2.6.22-rc6-mm1/broken-out/gregkh-usb-usb-oti6858-usb-serial-driver.patch )
			PATCH+=( $MIRROR/people/akpm/patches/2.6/2.6.22-rc6/2.6.22-rc6-mm1/broken-out/gregkh-usb-usb-oti6858-status.patch )
			PATCH+=( $PATCH_MIRROR/2.6.22-squashfs3.2-r2.patch.bz2 )
			;;
		*)
			#PATCH+=(  )
			;;
	esac
}

#=============================================================================#
#	colours
#=============================================================================#
if [[ -x $(type -p tput) ]]; then
	COLOR_ACTION=$(tput setaf 6)		# action	(cyan)
	COLOR_INFO=$(tput bold ; tput setaf 5)	# info		(pink)
	COLOR_SUCCESS=$(tput setaf 2)		# success	(green)
	COLOR_FAILURE=$(tput setaf 1)		# failure	(red)
	COLOR_NORM=$(tput sgr0)			# no colour	(reset to defaults)
fi

#=============================================================================#
#	process cli args
#=============================================================================#

while getopts b:dk:l:m:p opt; do
	case $opt in
		b)	# source directory
			SRCDIR=$OPTARG
			;;
		d)	# debug it
			set -x
			;;
		k)	# kernel version override
			unset LAZY
			KERNEL=$OPTARG
			;;
		l)
			KERNEL=$OPTARG
			LAZY="-${USER}-${DEF_CPU}-${REVISION}"
			;;
		m)	# mirror
			MIRROR=$OPTARG
			;;
		p)	# do nothing
			((NOACT++))
			;;
		\?)	# unknown option
			exit 1
			;;
	esac
done

#=============================================================================#
#	give linux the finger
#=============================================================================#
finger_latest_kernel() {
	local TYPE NAME KERN
	
	# Example: latest-stable-$name-$rev
	if [[ $1 =~ '^latest-(stable|prepatch|snapshot|mm)(-.*)?' ]]; then
		TYPE=${BASH_REMATCH[1]}
		NAME=${BASH_REMATCH[2]}
		KERN=$(wget -qO- ${MIRROR//\/pub\/linux\/kernel/\/kdist\/finger_banner} | \
			awk '/latest -?'$TYPE'/{ print $NF; exit }')
		
		if [[ $KERN ]]; then
			echo ${KERN}${NAME}
		fi
	fi
}

case $KERNEL in
	latest-*)
		KERNEL=$(finger_latest_kernel $KERNEL)
		if [[ ! $KERNEL ]]; then
			printf "E: ${COLOR_FAILURE}Unable to finger kernel version${COLOR_NORM}\n"
			exit 1
		fi
		;;
	*)
		;;
esac

KERNEL=${KERNEL}${LAZY}

#=============================================================================#
#	breakdown kernel string with regexp group matching
#=============================================================================#

if [[ $KERNEL =~ '^([0-9]+\.[0-9]+)\.([0-9]+)\.?([0-9]+)?-?(rc[0-9]+)?-?(git[0-9]+)?-?(mm[0-9]+)?-?([a-zA-Z]+[a-zA-Z0-9\._]*)?-?([a-zA-Z]+[a-zA-Z]*)?-?([0-9]+)?$' ]]; then
	KMV=${BASH_REMATCH[1]} # Major Version
	KRV=${BASH_REMATCH[2]} # Release Version
	KSV=${BASH_REMATCH[3]} # Stable Version
	KRC=${BASH_REMATCH[4]} # Release Candidate
	KGV=${BASH_REMATCH[5]} # Git Version
	KMM=${BASH_REMATCH[6]} # MM Version
	NAM=${BASH_REMATCH[7]} # Name
	MCP=${BASH_REMATCH[8]} # smp/ up
	REV=${BASH_REMATCH[9]} # Revision
	
	# Extra Version
	if [[ $KERNEL =~ '^[0-9]+\.[0-9]+\.[0-9]+(\.?[0-9]*-?.*)?-'$NAM'-?('$MCP')?-'$REV'$' ]]; then
		# cpu based name modifier
		CPU=$(uname -m)
		case $CPU in
			i?86)
				# no-op
				[[ $MCP ]] || MCP="smp"
				;;
			x86_64)
				[[ $NAM == *64 ]] || NAM=${NAM}64
				[[ $MCP ]] || MCP="smp"
				;;
			sparc)
				[[ $NAM == *32 ]] || NAM=${NAM}${CPU}32
				[[ $MCP ]] || MCP="up"
				;;
			*)
				[[ $NAM == *${CPU} ]] || NAM=${NAM}${CPU}
				[[ $MCP ]] || MCP="smp"
				;;
		esac
		# reform name modified KEV
		KEV=${BASH_REMATCH[1]}-$NAM-$MCP-$REV
	elif [[ $KERNEL =~ '^[0-9]+\.[0-9]+\.[0-9]+(\.?[0-9]*-.*)' ]]; then
		# generic/unamed kernel
		KEV=${BASH_REMATCH[1]}
	fi

	# reform (possibly) name modified kernel version
	KERNEL=$KMV.${KRV}${KEV}

	KERNEL_VARS=( KERNEL KMV KRV KSV KRC KGV KMM KEV NAM MCP REV )
else
	printf "E: ${COLOR_FAILURE}Unable to process ${COLOR_INFO}$KERNEL${COLOR_NORM}${COLOR_FAILURE} version string!${COLOR_NORM}\n"
	exit 1
fi

#=============================================================================#
#	upstream kernel && patch urls
#=============================================================================#

if [[ $KRC && ! $KSV ]]; then
	TARBALL=$MIRROR/v$KMV/linux-$KMV.$[$KRV-1].tar.bz2
else
	TARBALL=$MIRROR/v$KMV/linux-$KMV.$KRV.tar.bz2
fi

if [[ $KSV ]]; then
	if [[ $KRC ]]; then
		[[ $KSV != 1 ]] && KPATCH+=( $MIRROR/v$KMV/patch-$KMV.$KRV.$[$KSV-1].bz2 )
		for location in $MIRROR/v$KMV/stable-review $MIRROR/people/chrisw/stable $MIRROR/people/gregkh/stable $MIRROR/v$KMV/testing; do
			for suf in bz2 gz; do
				if wget --spider -q $location/patch-$KMV.$KRV.$KSV-$KRC.$suf; then
					KPATCH+=( $location/patch-$KMV.$KRV.$KSV-$KRC.$suf )
					break 2
				fi
			done
		done
		if [[ ! ${KPATCH[@]} ]]; then
			printf "E: ${COLOR_FAILURE}Unable to determine origin of stable rc patch!${COLOR_NORM}\n"
			exit 1
		fi
	else
		KPATCH+=( $MIRROR/v$KMV/patch-$KMV.$KRV.$KSV.bz2 )
	fi
else
	if [[ $KRC ]]; then
		KPATCH+=( $MIRROR/v$KMV/testing/patch-$KMV.$KRV-$KRC.bz2 )
	fi
	if [[ $KRC && $KMM ]]; then
		KPATCH+=( $MIRROR/people/akpm/patches/$KMV/$KMV.$KRV-$KRC/$KMV.$KRV-$KRC-$KMM/$KMV.$KRV-$KRC-$KMM.bz2 )
	fi
	if [[ $KRC && $KGV ]]; then
		KPATCH+=( $MIRROR/v$KMV/snapshots/patch-$KMV.$KRV-$KRC-$KGV.bz2 )
	fi
	if [[ ! $KRC && $KGV ]]; then
		KPATCH+=( $MIRROR/v$KMV/snapshots/patch-$KMV.$KRV-$KGV.bz2 )
	fi
	if [[ ! $KRC && $KMM ]]; then
		KPATCH+=( $MIRROR/people/akpm/patches/$KMV/$KMV.$KRV-$KRC/$KMV.$KRV-$KMM/$KMV.$KRV-$KMM.bz2 )
	fi
fi

#=============================================================================#
#	select & debug patch selection
#=============================================================================#

patches_for_kernel $KERNEL

if [[ $NOACT ]]; then
	for i in ${KERNEL_VARS[@]}; do
		eval printf "$i=\$$i\ "
	done
	printf "\nTARBALL=$TARBALL\n"
	for ((i = 0; i < ${#KPATCH[@]}; i++)); do
		printf "KPATCH[$i]=${KPATCH[$i]}\n"
	done
	for ((i = 0; i < ${#PATCH[@]}; i++)); do
		printf "PATCH[$i]=${PATCH[$i]}\n"
	done
	exit 0
fi

#=============================================================================#
#	GPL compliance
#=============================================================================#
DPKG_PATCH_DIR=$SRCDIR/linux-custom-patches-${KERNEL}-1

dpkg_patches() {
	[[ -x $(type -p fakeroot) && -x $(type -p dpkg-buildpackage) ]] || return
	[[ -d /usr/share/sidux-kernelhacking/linux-custom-patches ]] || return

	printf "${COLOR_ACTION}Preserving custom patches in debian archive${COLOR_NORM}...\n"
	printf "%-70s [" "  * ${COLOR_INFO}linux-custom-patches-${KERNEL}${COLOR_NORM}"

	mkdir -p $DPKG_PATCH_DIR/patches

	for patch in $@; do
		cp $SRCDIR/${patch##*/} $DPKG_PATCH_DIR/patches
	done

	cp -r /usr/share/sidux-kernelhacking/linux-custom-patches/* \
		$DPKG_PATCH_DIR
	
	for file in $DPKG_PATCH_DIR/debian/*; do
		sed -i "s/\%VER\%/${KERNEL}/g;\
			s/\%REVISION\%/1/g;\
			s/\%DEBFULLNAME\%/${DEBFULLNAME}/g;\
			s/\%DEBEMAIL\%/${DEBEMAIL}/g;\
			s/\%DATE\%/$(date --rfc-2822)/g" "$file"
	done

	for url in $TARBALL $@; do
		sed -i "s|\%PATCH_LIST\%|${url}\\n\\t\%PATCH_LIST\%|" \
			$DPKG_PATCH_DIR/debian/copyright
	done
	sed -i '/\%PATCH_LIST\%/d' $DPKG_PATCH_DIR/debian/copyright

	install -m 0755 $0 $DPKG_PATCH_DIR/linux-source-${KERNEL}.sh
	
	pushd $DPKG_PATCH_DIR &>/dev/null
		if fakeroot dpkg-buildpackage -uc -us &>/dev/null; then
			printf "${COLOR_SUCCESS}Ok${COLOR_NORM}]\n"
		else
			printf "${COLOR_FAILURE}Failed!${COLOR_NORM}]\n"
			return 1
		fi
	popd &>/dev/null

	rm -rf $DPKG_PATCH_DIR
	rm -f $SRCDIR/linux-custom-patches-${KERNEL}*.{dsc,changes,tar.gz}
}

#=============================================================================#
#	patch functions
#=============================================================================#

patch_it() {
	local PATCH_FILE=$1
	local PATCH_LEVEL=$2
	shift 2

	case ${PATCH_FILE} in
		*.gz)
			zcat $PATCH_FILE | patch -p$PATCH_LEVEL $@ &>/dev/null
			;;
		*.bz2)
			bzcat $PATCH_FILE | patch -p$PATCH_LEVEL $@ &>/dev/null
			;;
		*)
			patch -i $PATCH_FILE -p$PATCH_LEVEL $@ &>/dev/null
			;;
	esac

	return $?
}

apply_patches() {
	local RETVAL PATCH PATCH_LEVEL
	
	for patch in $@; do
		RETVAL=1
		PATCH_LEVEL=1
		PATCH=../${patch##*/}
		
		if [[ ! -f $PATCH ]]; then
			printf "\n\tE: ${COLOR_FAILURE}patch not found!${COLOR_NORM}\n"
			return 1
		fi
		
		printf "%-70s [" "  * ${COLOR_INFO}${PATCH#*/}${COLOR_NORM}"
		
		# try until --dry-run succeeds, then really patch it
		until [[ $RETVAL == 0 ]] || [[ $PATCH_LEVEL -lt 0 ]]; do
			if patch_it $PATCH $PATCH_LEVEL --force --dry-run --silent; then
				patch_it $PATCH $PATCH_LEVEL --silent
				RETVAL=$?
				break
			fi
			((PATCH_LEVEL--))
		done

		if [[ $RETVAL == 0 ]]; then
			printf "${COLOR_SUCCESS}Ok${COLOR_NORM}]\n"
			continue
		else
			printf "${COLOR_FAILURE}Failed!${COLOR_NORM}]\n"
		fi
		
		return $RETVAL
	done

	return 0
}

#=============================================================================#
#	do it
#=============================================================================#

mkdir -p $SRCDIR

printf "${COLOR_ACTION}Create ${COLOR_INFO}linux-$KERNEL${COLOR_NORM} @ ${COLOR_ACTION}$SRCDIR${COLOR_NORM}\n\n"

if [[ -d $SRCDIR/linux-$KERNEL || -d $SRCDIR/linux-$KMV ]]; then
	rm -rf $SRCDIR/linux-$KERNEL $SRCDIR/$DPKG_PATCH_DIR
	if [[ $KRC && ! $KSV ]]; then
		rm -rf $SRCDIR/linux-$KMV.$[$KRV-1]
	else
		rm -rf $SRCDIR/linux-$KMV.$KRV
	fi
fi

printf "${COLOR_ACTION}Downloading ${COLOR_INFO}${TARBALL##*/}${COLOR_NORM}..."
if wget -Ncq -O $SRCDIR/${TARBALL##*/} $TARBALL; then
	printf "\n"
else
	printf " ${COLOR_FAILURE}Failed!${COLOR_NORM}\n"
	exit 1
fi
printf "\n"

printf "${COLOR_ACTION}Downloading patches${COLOR_NORM}...\n"
for patch in ${KPATCH[@]} ${PATCH[@]}; do
	printf "%-70s [" "  * ${COLOR_INFO}${patch##*/}${COLOR_NORM}"
	if wget -Ncq -O $SRCDIR/${patch##*/} $patch; then
		printf "${COLOR_SUCCESS}Ok${COLOR_NORM}]\n"
	else
		printf "${COLOR_FAILURE}Failed!${COLOR_NORM}]\n"
		exit 1
	fi
done
printf "\n"

printf "${COLOR_ACTION}Unpacking ${COLOR_INFO}${TARBALL##*/}${COLOR_NORM}..."
if tar -C $SRCDIR -xjf $SRCDIR/${TARBALL##*/}; then
	if [[ $KRC && ! $KSV ]]; then
		mv $SRCDIR/linux-$KMV.$[$KRV-1] $SRCDIR/linux-$KERNEL
	else
		if [[ $KMV.$KRV != $KERNEL ]]; then
			mv $SRCDIR/linux-$KMV.$KRV $SRCDIR/linux-$KERNEL
		fi
	fi
	printf "\n"
else
	printf " ${COLOR_FAILURE}Failed!${COLOR_NORM}\n"
	exit 1
fi
printf "\n"

printf "${COLOR_ACTION}Applying patches${COLOR_NORM}...\n"
pushd $SRCDIR/linux-$KERNEL &>/dev/null
	apply_patches ${KPATCH[@]} ${PATCH[@]}
popd &>/dev/null
printf "\n"

dpkg_patches ${KPATCH[@]} ${PATCH[@]}

sed -i 's/^\(EXTRAVERSION\).*/\1 = '$KEV'/' $SRCDIR/linux-$KERNEL/Makefile
if [[ -f "/boot/config-$KERNEL" ]]; then
	cat /boot/config-$KERNEL > $SRCDIR/linux-$KERNEL/.config
fi
rm -f $SRCDIR/linux
ln -s linux-$KERNEL $SRCDIR/linux
printf "\n${COLOR_ACTION}Prepared ${COLOR_INFO}linux-$KERNEL${COLOR_NORM} @ ${COLOR_ACTION}$SRCDIR${COLOR_NORM}\n"

