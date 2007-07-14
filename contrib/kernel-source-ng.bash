#!/bin/bash -e
#
# License: GPL2
#

LANG=C
LC_ALL=C
export LANG LC_ALL

# kernel.org mirror
MIRROR="http://eu.kernel.org/pub/linux/kernel"
PATCH_MIRROR="http://sidux.com/files/patches"

# extra version string components
KERNEL=latest-stable
NAME="${USER:0:3}"
REVISION="1"

# staging directory
if ((UID)); then
	# user
	SRCDIR=~/src
else
	# root
	SRCDIR=/usr/src
fi

#%STATIC_VERSION%
[[ $STATIC_VERSION ]] && KERNEL="$STATIC_VERSION"

#=============================================================================#
#	kernel patch urls
#=============================================================================#
patches_for_kernel() {
	case "$1" in
		2.6.21*)
			PATCH+=( 
				http://gaugusch.at/acpi-dsdt-initrd-patches/acpi-dsdt-initrd-v0.8.4-2.6.21.patch
				$PATCH_MIRROR/t-sinus_111card-2.6.16.diff
				$PATCH_MIRROR/2.6.21-at76_usb20070511.diff.bz2
				ftp://ftp.filesystems.org/pub/unionfs/unionfs-2.x/linux-2.6.21.5-u3.diff.gz
				$MIRROR/people/akpm/patches/2.6/2.6.21-rc6/2.6.21-rc6-mm1/broken-out/gregkh-driver-nozomi.patch
				$PATCH_MIRROR/2.6.21-zr364xx.diff.bz2
				$PATCH_MIRROR/2.6.21_drivers-ata-ata_piix-postpone-pata.patch
				$PATCH_MIRROR/2.6.21-1.3194_x86_64-silence-up-apic-errors.patch
				$PATCH_MIRROR/2.6.21-1.3194_x86-dont-delete-cpu_devs-data.patch
				$PATCH_MIRROR/2.6.21-1.3194_x86-fix-oprofile.patch
				$PATCH_MIRROR/2.6.21-1.3194_x86-fsc-interrupt-controller-quirk.patch
				$PATCH_MIRROR/2.6.21-1.3194_mpc52xx-sdma.patch
				$PATCH_MIRROR/2.6.21-1.3194_mpc52xx-fec.patch
				$PATCH_MIRROR/2.6.21-1.3194_input-kill-stupid-messages.patch
				$PATCH_MIRROR/2.6.21-1.3194_kvm-19.patch
				$PATCH_MIRROR/2.6.21-1.3194_mm-udf-fixes.patch
				$PATCH_MIRROR/2.6.21-1.3194_sysfs-inode-allocator-oops.patch
				$PATCH_MIRROR/2.6.21-1.3194_xfs-umount-fix.patch
				$PATCH_MIRROR/2.6.21-1.3194_dvb-spinlock.patch
				$PATCH_MIRROR/2.6.21-1.3194_i82875-edac-pci-setup.patch
				$PATCH_MIRROR/2.6.21-1.3194_defaults-fat-utf8.patch
				$PATCH_MIRROR/2.6.21-1.3194_defaults-unicode-vt.patch
				$PATCH_MIRROR/2.6.21-1.3194_libata-hpa.patch
				$PATCH_MIRROR/2.6.21-1.3194_libata-sata_nv-adma.patch
				$PATCH_MIRROR/2.6.21-1.3194_libata-ali-atapi-dma.patch
				$PATCH_MIRROR/2.6.21-1.3194_libata-sata_nv-wildcard-removal.patch
				$PATCH_MIRROR/2.6.21-1.3194_libata-pata-pcmcia-new-ident.patch
				$PATCH_MIRROR/2.6.21-1.3194_libata-pata-hpt3x2n-correct-revision-boundary.patch
				$PATCH_MIRROR/2.6.21-1.3194_libata-pata-sis-fix-timing.patch
				$PATCH_MIRROR/2.6.21-1.3194_wireless.patch
				$PATCH_MIRROR/2.6.21-1.3194_git-wireless-dev.patch
				$PATCH_MIRROR/2.6.21-1.3194_git-iwlwifi.patch
				$PATCH_MIRROR/2.6.21-1.3194_mac80211-fixes.patch
				$PATCH_MIRROR/2.6.21-1.3194_acpi-keep-tsc-stable-when-lapic-timer-c2-ok-is-set.patch
				$PATCH_MIRROR/2.6.21-1.3194_clockevents-fix-resume-logic.patch
				$PATCH_MIRROR/2.6.21-1.3194_acpi-dock-oops.patch
				$PATCH_MIRROR/2.6.21_ati-sb700.diff
				$PATCH_MIRROR/at76_usb-mac80211.diff
				$PATCH_MIRROR/zd1211rw-asus-2.6.21.diff
				$PATCH_MIRROR/2.6.21.4_futex.diff
			)
			;;
		2.6.22*)
			PATCH+=(
				http://gaugusch.at/acpi-dsdt-initrd-patches/acpi-dsdt-initrd-v0.8.4-2.6.21.patch
				$PATCH_MIRROR/t-sinus_111card-2.6.16.diff
				ftp://ftp.filesystems.org/pub/unionfs/unionfs-2.x/linux-2.6.22.1-u1.diff.gz
				$PATCH_MIRROR/2.6.22-at76_usb20070621.diff.bz2
				$PATCH_MIRROR/2.6.22-8_git-wireless-dev.patch.gz
				$PATCH_MIRROR/2.6.22-8_rtl8187.patch.gz
				$PATCH_MIRROR/2.6.22-1.3242_defaults-fat-utf8.patch.bz2
				$PATCH_MIRROR/2.6.22-1.3242_defaults-unicode-vt.patch.bz2
				#$PATCH_MIRROR/2.6.22-1.3242_input-kill-stupid-messages.patch.bz2
				$MIRROR/people/akpm/patches/2.6/2.6.22-rc6/2.6.22-rc6-mm1/broken-out/git-ipwireless_cs.patch
				$MIRROR/people/akpm/patches/2.6/2.6.22-rc6/2.6.22-rc6-mm1/broken-out/gregkh-driver-nozomi.patch
				$MIRROR/people/akpm/patches/2.6/2.6.22-rc6/2.6.22-rc6-mm1/broken-out/fix-gregkh-driver-nozomi.patch
				$MIRROR/people/akpm/patches/2.6/2.6.22-rc6/2.6.22-rc6-mm1/broken-out/gregkh-usb-usb-oti6858-usb-serial-driver.patch
				$MIRROR/people/akpm/patches/2.6/2.6.22-rc6/2.6.22-rc6-mm1/broken-out/gregkh-usb-usb-oti6858-status.patch
				$PATCH_MIRROR/2.6.22-squashfs3.2-r2.patch.bz2
				$PATCH_MIRROR/2.6.22.1_aacraid_security.patch
				$PATCH_MIRROR/2.6.22_cfg80211_netdev_security.diff
			)
			;;
		*)
			#PATCH+=(
			#	insert patch URLs here
			#)
			;;
	esac
}

#=============================================================================#
#	colours
#=============================================================================#
if [[ -x $(which tput 2>/dev/null) ]]; then
	COLOR_ACTION=$(tput setaf 6)		# action	(cyan)
	COLOR_INFO=$(tput bold ; tput setaf 5)	# info		(pink)
	COLOR_SUCCESS=$(tput setaf 2)		# success	(green)
	COLOR_FAILURE=$(tput setaf 1)		# failure	(red)
	COLOR_NORM=$(tput sgr0)			# no colour	(reset to defaults)
fi

#=============================================================================#
#	process cli args
#=============================================================================#

while getopts b:c:dk:l:m:n:pr:x opt; do
	case $opt in
		b)	# source directory
			SRCDIR=$OPTARG
			;;
		c)
			DEF_CPU=$OPTARG
			;;
		d|x)	# debug it
			set -x
			;;
		k)	# kernel flavour
			KERNEL=$OPTARG
			;;
		l)	# kernel flavour, append name
			KERNEL=$OPTARG
			((LAZY++))
			;;
		m)	# mirror
			MIRROR=$OPTARG
			;;
		n)	# name
			NAME=$OPTARG
			;;
		p)	# do nothing
			((NOACT++))
			;;
		r)
			REVISION=$OPTARG
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
	local TYPE KERN EXTRA
	
	# Example: latest-stable-$name-$rev
	if [[ $1 =~ '^latest-(stable|prepatch|snapshot|mm)(-.*)?' ]]; then
		TYPE=${BASH_REMATCH[1]}
		EXTRA=${BASH_REMATCH[2]}
		KERN=$(wget -qO- ${MIRROR//\/pub\/linux\/kernel/\/kdist\/finger_banner} | \
			awk '/^The latest -?'$TYPE'/{ print $NF; exit }')
		
		if [[ $KERN ]]; then
			echo ${KERN}${EXTRA}
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

	: ${NAM:=$NAME}
	: ${MCP:=$DEF_CPU}
	: ${REV:=$REVISION}
	
	# Extra Version
	if [[ $LAZY && $KERNEL =~ '^[0-9]+\.[0-9]+\.[0-9]+(\.?[0-9]*-?.*)?-?('$NAM')?-?('$MCP')?-?('$REV')?$' ]]; then
		# cpu based name modifier
		CPU=$(uname -m)
		case $CPU in
			i?86)
				# no-op
				: ${MCP:="smp"}
				;;
			x86_64)
				[[ $NAM == *64 ]] || NAM=${NAM}64
				: ${MCP:="smp"}
				;;
			sparc)
				[[ $NAM == *32 ]] || NAM=${NAM}${CPU}32
				: ${MCP:="up"}
				;;
			*)
				[[ $NAM == *${CPU} ]] || NAM=${NAM}${CPU}
				: ${MCP:="smp"}
				;;
		esac
		# reform with name modified KEV
		KERNEL=${KMV}.${KRV}${BASH_REMATCH[1]}-${NAM}-${MCP}-${REV}
	else
		KERNEL=${KERNEL}-${NAM}-${REV}
	fi

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

	printf "${COLOR_ACTION}Preserving custom patches in debian archive${COLOR_NORM}...\n"
	printf "%-70s [" "  * ${COLOR_INFO}linux-custom-patches-${KERNEL}${COLOR_NORM}"
	if [[ ! -d /usr/share/sidux-kernelhacking/linux-custom-patches ]] || \
	   [[ ! -x $(which fakeroot) ]] || \
	   [[ ! -x $(which dpkg-buildpackage) ]] || \
	   [[ ! -r /usr/share/cdbs/1/rules/debhelper.mk ]]; then
		printf "${COLOR_FAILURE}Skipped!${COLOR_NORM}]\n"
		printf "    ${COLOR_FAILURE}Ensure to have the following packages installed:${COLOR_NORM}\n"
		printf "    - cdbs\n"
		printf "    - dpkg-dev\n"
		printf "    - fakeroot\n"
		printf "    - sidux-kernelhacking\n"

		return 0
	fi

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
			zcat $PATCH_FILE | patch -p$PATCH_LEVEL $@
			;;
		*.bz2)
			bzcat $PATCH_FILE | patch -p$PATCH_LEVEL $@
			;;
		*)
			patch -i $PATCH_FILE -p$PATCH_LEVEL $@
			;;
	esac

	return $?
}

apply_patches() {
	local RETVAL PATCH PATCH_LEVEL
	
	for patch in $@; do
		RETVAL=999
		PATCH_LEVEL=1
		PATCH=../${patch##*/}
		
		if [[ ! -f $PATCH ]]; then
			printf "\n\tE: ${COLOR_FAILURE}patch not found!${COLOR_NORM}\n"
			return 1
		fi
		
		printf "%-70s [" "  * ${COLOR_INFO}${PATCH#*/}${COLOR_NORM}"

		set +e
		
		# try until --dry-run succeeds, then really patch it
		until [[ $PATCH_LEVEL -lt 0 ]]; do
			patch_it $PATCH $PATCH_LEVEL --force --dry-run &>/dev/null
			# process return codes as per patch(1)
			case "$?" in
				2)
					# more serious trouble
					;;
				1)
					if patch_it $PATCH $PATCH_LEVEL --force --dry-run | head -n 1 | \
						grep -q "^can't find file to patch"; then
						((PATCH_LEVEL--)) && continue
					fi
					# some hunks cannot be applied
					printf "${COLOR_FAILURE}Failed!${COLOR_NORM}]\n"
					printf "${COLOR_FAILURE}--------------------------${COLOR_NORM}\n"
					# verbose dump of patch failure
					patch_it $PATCH $PATCH_LEVEL --force --dry-run
					printf "${COLOR_FAILURE}--------------------------${COLOR_NORM}\n"
					;;
				0)
					# all hunks are applied successfully
					patch_it $PATCH $PATCH_LEVEL --silent
					RETVAL=$?
					printf "${COLOR_SUCCESS}Ok${COLOR_NORM}]\n"
					;;
			esac
			break
		done

		set -e

		[[ $RETVAL == 0 ]] && continue
		
		printf "${COLOR_FAILURE}${patch##*/} failed to apply!${COLOR_NORM}\n"
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

