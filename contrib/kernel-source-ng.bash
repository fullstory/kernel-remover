#!/bin/bash -e
#
# License: GPL2
#

# kernel version
KERNEL=2.6.20.3-kel-1

# staging directory
SRCDIR=~/src

# kernel.org mirror
MIRROR="http://www.kernel.org/pub/linux/kernel"

#=============================================================================#
#	kernel patch urls
#=============================================================================#
patches_for_kernel() {
	case "$1" in
		2.6.20.3*)
			PATCH+=( http://ck.kolivas.org/patches/staircase-deadline/2.6.20.3-rsdl-0.31.patch )
			;;
	esac
}

#=============================================================================#
#	colours
#=============================================================================#
if [[ -x $(type -p tput) ]]; then
	CYAN=$(tput setaf 6)			# action
	YELLOW=$(tput bold ; tput setaf 3)	# info
	GREEN=$(tput setaf 2)			# success
	RED=$(tput setaf 1)			# failure
	NORM=$(tput sgr0)			# no colour
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
						printf "E: ${RED}Unable to finger kernel version${NORM}\n"
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
	if [[ $KERNEL =~ '^[0-9]+\.[0-9]+\.[0-9]+(\.?[0-9]*-.*)-'$NAM'-'$REV'$' ]]; then
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
	printf "E: ${RED}Unable to process ${YELLOW}$KERNEL${NORM}${RED} version string!${NORM}\n"
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
	if [[ ! $KRC ]]; then
		KPATCH+=( $MIRROR/v$KMV/patch-$KMV.$KRV.$KSV.bz2 )
	else
		for location in $MIRROR/people/chrisw/stable $MIRROR/people/gregkh/stable $MIRROR/v$KMV/testing; do
			for suf in bz2 gz; do
				if wget --spider -q $location/patch-$KMV.$KRV.$KSV-$KRC.$suf; then
					KPATCH+=( $location/patch-$KMV.$KRV.$KSV-$KRC.$suf )
					break 2
				fi
			done
		done
		if [[ ! ${KPATCH[@]} ]]; then
			printf "E: ${RED}Unable to determine origin of stable rc patch!${NORM}\n"
			exit 1
		fi
	fi
else
	if [[ $KRC && ! $KGV ]]; then
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
			printf "\n\tE: ${RED}patch not found!${NORM}\n"
			return 1
		fi
		
		printf "%-70s [" "  * ${YELLOW}${PATCH#*/}${NORM}"
		
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
			printf "${GREEN}Ok${NORM}]\n"
			continue
		else
			printf "${RED}Failed!${NORM}]\n"
		fi
		
		return $RETVAL
	done

	return 0
}

#=============================================================================#
#	do it
#=============================================================================#

if [[ -d $SRCDIR/linux-$KERNEL || -d $SRCDIR/linux-$KMV ]]; then
	rm -rf $SRCDIR/linux-$KERNEL
	if [[ $KRC && ! $KSV ]]; then
		rm -rf $SRCDIR/linux-$KMV.$[$KRV-1]
	else
		rm -rf $SRCDIR/linux-$KMV.$KRV
	fi
fi

printf "${CYAN}Downloading ${YELLOW}${TARBALL##*/}${NORM}..."
if wget -Ncq -O $SRCDIR/${TARBALL##*/} $TARBALL; then
	printf "\n"
else
	printf " ${RED}Failed!${NORM}\n"
	exit 1
fi
printf "\n"

printf "${CYAN}Downloading patches${NORM}...\n"
for patch in ${KPATCH[@]} ${PATCH[@]}; do
	printf "%-70s [" "  * ${YELLOW}${patch##*/}${NORM}"
	if wget -Ncq -O $SRCDIR/${patch##*/} $patch; then
		printf "${GREEN}Ok${NORM}]\n"
	else
		printf "${RED}Failed!${NORM}]\n"
		exit 1
	fi
done
printf "\n"

printf "${CYAN}Unpacking ${YELLOW}${TARBALL##*/}${NORM}..."
if tar -C $SRCDIR -xjf $SRCDIR/${TARBALL##*/}; then
	if [[ $KRC && ! $KSV ]]; then
		mv $SRCDIR/linux-$KMV.$[$KRV-1] $SRCDIR/linux-$KERNEL
	else
		mv $SRCDIR/linux-$KMV.$KRV $SRCDIR/linux-$KERNEL
	fi
	printf "\n"
else
	printf " ${RED}Failed!${NORM}\n"
	exit 1
fi
printf "\n"

printf "${CYAN}Applying patches${NORM}...\n"
pushd $SRCDIR/linux-$KERNEL &>/dev/null
	apply_patches ${KPATCH[@]} ${PATCH[@]}
popd &>/dev/null
printf "\n"

sed -i 's/^\(EXTRAVERSION\).*/\1 = '$KEV'/' $SRCDIR/linux-$KERNEL/Makefile
if [[ -f "/boot/config-$KERNEL" ]]; then
	cat /boot/config-$KERNEL > $SRCDIR/linux-$KERNEL/.config
fi
rm -f $SRCDIR/linux
ln -s linux-$KERNEL $SRCDIR/linux
printf "${CYAN}Prepared ${YELLOW}linux-$KERNEL${NORM} @ ${CYAN}$SRCDIR${NORM}\n"
