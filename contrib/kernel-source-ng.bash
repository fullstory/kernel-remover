#!/bin/bash -e
#
# License: GPL2
#

# kernel.org mirror
MIRROR="http://zeus2.kernel.org/pub/linux/kernel"

# kernel version
KERNEL="$(wget -qO- ${MIRROR//\/pub\/linux\/kernel/\/kdist\/finger_banner} | awk '/latest -?'stable'/{ print $NF; exit }')-$(getent passwd $(id -u) | cut -d\: -f1)-1"

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

#=============================================================================#
#	kernel patch urls
#=============================================================================#
patches_for_kernel() {
	case "$1" in
		2.6.20*slh*)
			PATCH+=( http://gaugusch.at/acpi-dsdt-initrd-patches/acpi-dsdt-initrd-v0.8.3-2.6.20.patch )
			PATCH+=( http://sidux.com/files/patches/t-sinus_111card-2.6.16.diff )
			PATCH+=( http://sidux.com/files/patches/2.6.20-at76c503a20070307.diff.bz2 )
			PATCH+=( $MIRROR/people/akpm/patches/2.6/2.6.20-rc6/2.6.20-rc6-mm3/broken-out/2.6-sony_acpi4.patch )
			PATCH+=( $MIRROR/people/akpm/patches/2.6/2.6.20-rc6/2.6.20-rc6-mm3/broken-out/pl2303-willcom-ws002in-support.patch )
			PATCH+=( $MIRROR/people/akpm/patches/2.6/2.6.21-rc3/2.6.21-rc3-mm2/broken-out/gregkh-driver-nozomi.patch )
			;;
		2.6.21*slh*)
			PATCH+=( http://gaugusch.at/acpi-dsdt-initrd-patches/acpi-dsdt-initrd-v0.8.3-2.6.20.patch )
			PATCH+=( http://sidux.com/files/patches/t-sinus_111card-2.6.16.diff )
			PATCH+=( http://sidux.com/files/patches/2.6.20-at76c503a20070307.diff.bz2 )
			;;
		*)
			#PATCH+=( )
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

#=============================================================================#
#	process cli args
#=============================================================================#

while getopts b:dk:p opt; do
	case $opt in
		b)	# source directory
			SRCDIR=$OPTARG
			;;
		d)	# debug it
			set -x
			;;
		k)	# kernel version override
			case $OPTARG in
				latest-*)
					KERNEL=$(finger_latest_kernel $OPTARG)
					if [[ ! $KERNEL ]]; then
						printf "E: ${COLOR_FAILURE}Unable to finger kernel version${COLOR_NORM}\n"
						exit 1
					fi
					;;
				*)
					KERNEL=$OPTARG
					;;
			esac
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

mkdir -p $SRCDIR || exit 1

#=============================================================================#
#	breakdown kernel string with regexp group matching
#=============================================================================#

if [[ $KERNEL =~ '^([0-9]+\.[0-9]+)\.([0-9]+)\.?([0-9]+)?-?(rc[0-9]+)?-?(git[0-9]+)?-?(mm[0-9]+)?-?([a-zA-Z]+[a-zA-Z0-9\._]*)?-?([0-9]+)?$' ]]; then
	KMV=${BASH_REMATCH[1]} # Major Version
	KRV=${BASH_REMATCH[2]} # Release Version
	KSV=${BASH_REMATCH[3]} # Stable Version
	KRC=${BASH_REMATCH[4]} # Release Candidate
	KGV=${BASH_REMATCH[5]} # Git Version
	KMM=${BASH_REMATCH[6]} # MM Version
	NAM=${BASH_REMATCH[7]} # Name
	REV=${BASH_REMATCH[8]} # Revision
	
	# Extra Version
	if [[ $KERNEL =~ '^[0-9]+\.[0-9]+\.[0-9]+(\.?[0-9]*-?.*)?-'$NAM'-'$REV'$' ]]; then
		# cpu based name modifier
		CPU=$(uname -m)
		case $CPU in
			i?86)
				# no-op
				;;
			x86_64)
				[[ $NAM == *64 ]] || NAM=${NAM}64
				;;
			*)
				[[ $NAM == *${CPU} ]] || NAM=${NAM}${CPU}
				;;
		esac
		# reform name modified KEV
		KEV=${BASH_REMATCH[1]}-$NAM-$REV
	elif [[ $KERNEL =~ '^[0-9]+\.[0-9]+\.[0-9]+(\.?[0-9]*-.*)' ]]; then
		# generic/unamed kernel
		KEV=${BASH_REMATCH[1]}
	fi

	# reform (possibly) name modified kernel version
	KERNEL=$KMV.${KRV}${KEV}

	KERNEL_VARS=( KERNEL KMV KRV KSV KRC KGV KMM KEV NAM REV )
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
	KPATCH+=( $MIRROR/v$KMV/patch-$KMV.$KRV.$KSV.bz2 )
	if [[ $KRC ]]; then
		for location in $MIRROR/people/chrisw/stable $MIRROR/people/gregkh/stable $MIRROR/v$KMV/testing; do
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
		mv $SRCDIR/linux-$KMV.$KRV $SRCDIR/linux-$KERNEL
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

