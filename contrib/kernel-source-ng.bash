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
KERNEL=stable
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

# source personal config
if [[ -s $HOME/.kernel-sourcerc ]]; then
	source $HOME/.kernel-sourcerc
fi

#%STATIC_VERSION%
[[ $STATIC_VERSION ]] && KERNEL="$STATIC_VERSION"

# regular expression use to match kernel string
KREGEXP="^([0-9]+\.[0-9]+)\.([0-9]+)\.?([0-9]+)?-?(rc[0-9]+)?-?(git[0-9]+)?-?(mm[0-9]+)?$"
# ${BASH_REMATCH[1]} # Major Version
# ${BASH_REMATCH[2]} # Release Version
# ${BASH_REMATCH[3]} # Stable Version
# ${BASH_REMATCH[4]} # Release Candidate
# ${BASH_REMATCH[5]} # Git Version
# ${BASH_REMATCH[6]} # MM Version


#=============================================================================#
#	kernel patch urls
#=============================================================================#
patches_for_kernel() {
	case "$1" in
		2.6.22*)
			PATCH+=(
				http://gaugusch.at/acpi-dsdt-initrd-patches/acpi-dsdt-initrd-v0.8.4-2.6.21.patch
				$PATCH_MIRROR/t-sinus_111card-2.6.16.diff
				ftp://ftp.filesystems.org/pub/unionfs/unionfs-2.x/linux-2.6.22.1-u1.diff.gz
				$PATCH_MIRROR/2.6.22-at76_usb20070621.diff.bz2
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
				$PATCH_MIRROR/2.6.22_softmac-set-essid-state-fix.patch
				$MIRROR/people/linville/wireless-2.6/upstream-merged/0001-mac80211-Add-support-for-SIOCGIWRATE-ioctl-to-pro.patch
				$MIRROR/people/linville/wireless-2.6/upstream-merged/0002-mac80211-Set-low-initial-rate-in-rc80211_simple.patch
				$PATCH_MIRROR/2.6.22.1_2.6.22-8_rtl8187.patch.gz
				#http://sidux.net/kelmo/tmp/patches/2.6.22.1-iwlwifi-0.1.1-patch_kernel.patch.gz
				$PATCH_MIRROR/2.6.22.1-iwlwifi-0.0.38-patch_kernel.patch.gz
				$PATCH_MIRROR/iwlwifi-csa-compat-fix.patch
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
	A=$(tput setaf 6)		# action	(cyan)
	I=$(tput bold ; tput setaf 5)	# info		(pink)
	S=$(tput setaf 2)		# success	(green)
	F=$(tput setaf 1)		# failure	(red)
	N=$(tput sgr0)			# no colour	(reset to defaults)
fi

#=============================================================================#
#	help
#=============================================================================#
print_help() {
	cat \
<<EOF

    kernel-source-ng - download and patch a kernel tree
  =======================================================

  -b <build dir>        - staging area for linux source tree
                          Defaults: ~/src (user) or /usr/src (root user)

  -k <kernel string>    - target kernel version
                          
			  Special strings "stable" "prepatch" "snapshot" "mm"
			  can be given and the script will try its hardest to
			  lookup those kernel versions as listed at:
			    ${MIRROR//\/pub\/linux\/kernel//kdist/finger_banner}

			  Otherwise, the given string must match with the
			  following regular expression:
			    $KREGEXP

			  Examples:
			        2.6.22
				2.6.21.1
                                2.6.23-rc1-git5
                          
  -m <mirror url>       - kernel.org mirror
                          Defaults: $MIRROR

  -n <name string>      - name or label to put in extraversion string
                          Defaults: $NAME

  -p                    - print only, don't actually do anything

  -r <revision #>       - revision number
                          Defaults: $REVISION

  -v                    - verbose mode

  -d or -x              - debug bash shell execution (set -x)

  -h                    - this help information ;-)

EOF
}

#=============================================================================#
#	process cli args
#=============================================================================#

while getopts b:c:dhk:l:m:n:pr:vx opt; do
	case $opt in
		b)	# source directory
			SRCDIR=$OPTARG
			;;
		c)	# cpu type
			MCP=$OPTARG
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
		p)	# do nothing, print only
			((NOACT++))
			;;
		r)	# revision number
			REVISION=$OPTARG
			;;
		v)	# verbosity
			((VERBOSITY++))
			;;
		h|\?)	# unknown option
			print_help
			exit 1
			;;
	esac
done

#=============================================================================#
#	give linux the finger
#=============================================================================#
finger_latest_kernel() {
	local KERN
	
	KERN=$(wget -qO- ${2//\/pub\/linux\/kernel//kdist/finger_banner} | \
		awk '/^The latest -?'$1'/{ print $NF; exit }')
		
	[[ $KERN ]] && echo ${KERN}
}

case $KERNEL in
	latest-stable|latest-prepatch|latest-snapshot|latest-mm|stable|prepatch|snapshot|mm)
		KERNEL=$(finger_latest_kernel ${KERNEL#latest-} $MIRROR)
		if [[ ! $KERNEL ]]; then
			printf "E: ${F}Unable to finger kernel version${N}\n"
			exit 1
		fi
		;;
	*)
		if [[ ! $KERNEL =~ $KREGEXP ]]; then
			print_help
			printf "${F}Invalid kernel version string!${N}\n"
			exit 1
		fi
		;;
esac

#=============================================================================#
#	breakdown kernel string with regexp group matching
#=============================================================================#

if [[ $KERNEL =~ $KREGEXP ]]; then
	KMV=${BASH_REMATCH[1]} # Major Version
	KRV=${BASH_REMATCH[2]} # Release Version
	KSV=${BASH_REMATCH[3]} # Stable Version
	KRC=${BASH_REMATCH[4]} # Release Candidate
	KGV=${BASH_REMATCH[5]} # Git Version
	KMM=${BASH_REMATCH[6]} # MM Version

	# Extra Version
	if [[ $LAZY && $KERNEL =~ '^[0-9]+\.[0-9]+\.[0-9]+(\.?[0-9]*-?.*)?$' ]]; then
		# cpu based name modifier
		CPU=$(uname -m)
		case $CPU in
			i?86)
				# no-op
				: ${MCP:="smp"}
				;;
			x86_64)
				[[ $NAME == *64 ]] || NAME=${NAME}64
				: ${MCP:="smp"}
				;;
			sparc)
				[[ $NAME == *32 ]] || NAME=${NAME}${CPU}32
				: ${MCP:="up"}
				;;
			*)
				[[ $NAME == *${CPU} ]] || NAME=${NAME}${CPU}
				: ${MCP:="smp"}
				;;
		esac
		# reform with name modified KEV
		KERNEL=${KMV}.${KRV}${BASH_REMATCH[1]}-${NAME}-${MCP}-${REVISION}
	else
		KERNEL=${KERNEL}-${NAME}-${REVISION}
	fi

	if [[ $KERNEL =~ '^[0-9]+\.[0-9]+\.[0-9]+(\.?[0-9]*-?.*)?$' ]]; then
		KEV=${BASH_REMATCH[1]}
	fi
else
	printf "E: ${F}Unable to process ${I}$KERNEL${N}${F} version string!${N}\n"
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
			printf "E: ${F}Unable to determine origin of stable rc patch!${N}\n"
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

if [[ $NOACT || $VERBOSITY ]]; then
	for i in KERNEL KMV KRV KSV KRC KGV KMM KEV NAME MCP REVISION; do
		eval printf "$i=\$$i\ "
	done
	printf "\nTARBALL=$TARBALL\n"
	for ((i = 0; i < ${#KPATCH[@]}; i++)); do
		printf "KPATCH[$i]=${KPATCH[$i]}\n"
	done
	for ((i = 0; i < ${#PATCH[@]}; i++)); do
		printf "PATCH[$i]=${PATCH[$i]}\n"
	done
fi

[[ $NOACT ]] && exit 0

#=============================================================================#
#	GPL compliance
#=============================================================================#
DPKG_PATCH_DIR=$SRCDIR/linux-custom-patches-${KERNEL}-1

dpkg_patches() {

	printf "${A}Preserving custom patches in debian archive${N}...\n"
	printf "%-70s [" "  * ${I}linux-custom-patches-${KERNEL}${N}"
	if [[ ! -d /usr/share/sidux-kernelhacking/linux-custom-patches ]] || \
	   [[ ! -x $(which fakeroot) ]] || \
	   [[ ! -x $(which dpkg-buildpackage) ]] || \
	   [[ ! -r /usr/share/cdbs/1/rules/debhelper.mk ]]; then
		printf "${F}Skipped!${N}]\n"
		printf "    ${F}Ensure to have the following packages installed:${N}\n"
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
		if dpkg-buildpackage -rfakeroot -uc -us &>/dev/null; then
			printf "${S}Ok${N}]\n"
		else
			printf "${F}Failed!${N}]\n"
			return 1
		fi
	popd &>/dev/null

	rm -rf $DPKG_PATCH_DIR
	rm -f $SRCDIR/linux-custom-patches-${KERNEL}*.{dsc,changes,tar.gz}
}

download_patches() {
	local WGET_OPTS WGET_RETVAL

	if [[ $VERBOSITY ]]; then
		WGET_OPTS=( -N -c -v )
	else
		WGET_OPTS=( -N -c -q )
	fi

	for patch in ${@}; do
		printf "%-70s [" "  * ${I}${patch##*/}${N}"
		[[ $VERBOSITY ]] && printf "${I}downloading...${N}]\n"
		
		set +e
		
		wget -T 10 ${WGET_OPTS[@]} $patch
		WGET_RETVAL=$?
		
		set -e

		case $WGET_RETVAL in
			0)
				[[ $VERBOSITY ]] && printf "%-70s [" "  * ${I}${patch##*/}${N}"
				printf "${S}Ok${N}]\n"
				;;
			*)
				printf "${F}Failed!${N}]\n"
				return $WGET_RETVAL
				;;
		esac
	done

	return 0
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
			printf "\n\tE: ${F}patch not found!${N}\n"
			return 1
		fi
		
		printf "%-70s [" "  * ${I}${PATCH#*/}${N}"

		set +e
		
		# try until --dry-run succeeds, then really patch it
		until [[ $PATCH_LEVEL -lt 0 ]]; do
			patch_it $PATCH $PATCH_LEVEL --force --dry-run &>/dev/null
			# process return codes as per patch(1)
			case "$?" in
				2)	# more serious trouble
					;;
				1)	# some hunks cannot be applied
					if patch_it $PATCH $PATCH_LEVEL --force --dry-run | head -n 1 | \
						grep -q "^can't find file to patch"; then
						# wrong -p or --strip option
						((PATCH_LEVEL--)) && continue
					fi
					# hunks really cannot be applied
					printf "${F}Failed!${N}]\n"
					printf "${F}--------------------------${N}\n"
					# verbose dump of patch failure
					patch_it $PATCH $PATCH_LEVEL --force --dry-run
					printf "${F}--------------------------${N}\n"
					;;
				0)
					if [[ $VERBOSITY ]]; then
						printf "${I}patching...${N}]\n"
						patch_it $PATCH $PATCH_LEVEL
						RETVAL=$?
						printf "%-70s [" "  * ${I}${PATCH#*/}${N}"
					else
						# all hunks are applied successfully
						patch_it $PATCH $PATCH_LEVEL --silent
						RETVAL=$?
					fi
					printf "${S}Ok${N}]\n"
					;;
			esac
			break
		done

		set -e

		[[ $RETVAL == 0 ]] && continue
		
		printf "${F}${patch##*/} failed to apply!${N}\n"
		return $RETVAL
	done

	return 0
}

#=============================================================================#
#	do it
#=============================================================================#

mkdir -p $SRCDIR

printf "${A}Create ${I}linux-$KERNEL${N} @ ${A}$SRCDIR${N}\n\n"

if [[ -d $SRCDIR/linux-$KERNEL || -d $SRCDIR/linux-$KMV ]]; then
	rm -rf $SRCDIR/linux-$KERNEL $SRCDIR/$DPKG_PATCH_DIR
	if [[ $KRC && ! $KSV ]]; then
		rm -rf $SRCDIR/linux-$KMV.$[$KRV-1]
	else
		rm -rf $SRCDIR/linux-$KMV.$KRV
	fi
fi

printf "${A}Downloading ${I}${TARBALL##*/}${N}..."
if wget -Ncq -O $SRCDIR/${TARBALL##*/} $TARBALL; then
	printf "\n"
else
	printf " ${F}Failed!${N}\n"
	exit 1
fi
printf "\n"

printf "${A}Downloading patches${N}...\n"
pushd $SRCDIR &>/dev/null
	download_patches ${KPATCH[@]} ${PATCH[@]}
popd &>/dev/null
printf "\n"

printf "${A}Unpacking ${I}${TARBALL##*/}${N}..."
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
	printf " ${F}Failed!${N}\n"
	exit 1
fi
printf "\n"

printf "${A}Applying patches${N}...\n"
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
printf "\n${A}Prepared ${I}linux-$KERNEL${N} @ ${A}$SRCDIR${N}\n"

