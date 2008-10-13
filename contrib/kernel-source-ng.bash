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
	SRCDIR=$HOME/src
else
	# root
	SRCDIR=/usr/src
fi

# source personal config
if [[ -s $HOME/.kernel-sourcerc ]]; then
	source $HOME/.kernel-sourcerc
fi

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
if type -p tput >/dev/null; then
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

  -i                    - copyright information

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

  -u                    - omit local patches and just create an upstream/ 
                          vanilla kernel tree

  -v                    - verbose mode

  -d or -x              - debug bash shell execution (set -x)

  -h                    - this help information ;-)

EOF
}

print_copyright() {
	cat \
<<EOF

Copyright (C) 2006-2008 Kel Modderman <kel@otaku42.de>
Copyright (C) 2006-2007 Stefan Lippers-Hollmann <s.l-h@gmx.de>

F.U.L.L.S.T.O.R.Y Project Homepage:
http://developer.berlios.de/projects/fullstory

F.U.L.L.S.T.O.R.Y Subversion Archive:
svn://svn.berlios.de/fullstory/trunk
http://svn.berlios.de/svnroot/repos/fullstory
http://svn.berlios.de/viewcvs/fullstory (viewcvs)
http://svn.berlios.de/wsvn/fullstory (websvn)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; version 2 of the 
License only.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this package; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston,
MA 02110-1301, USA.

On Debian GNU/Linux systems, the text of the GPL license can be
found in /usr/share/common-licenses/GPL.

EOF
}

#=============================================================================#
#	process cli args
#=============================================================================#

while getopts b:c:dhik:l:m:n:pr:vux opt; do
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
		i)	# display copyright information
			print_copyright
			exit 0
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
		u)	# vanilla upstream kernel, don't apply private patches
			((VANILLA++))
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
	TARBALL=$MIRROR/v$KMV/linux-$KMV.$((KRV-1)).tar.bz2
else
	TARBALL=$MIRROR/v$KMV/linux-$KMV.$KRV.tar.bz2
fi

if [[ $KSV ]]; then
	if [[ $KRC ]]; then
		[[ $KSV != 1 ]] && KPATCH+=( $MIRROR/v$KMV/patch-$KMV.$KRV.$(($KSV-1)).bz2 )
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

[[ ! $VANILLA ]] && patches_for_kernel $KERNEL

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

download_patches() {
	local WGET_OPTS WGET_RETVAL

	if [[ $VERBOSITY ]]; then
		WGET_OPTS=( -Ncv )
	else
		WGET_OPTS=( -Ncq )
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
if wget -cq -O $SRCDIR/${TARBALL##*/} $TARBALL; then
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
		mv $SRCDIR/linux-$KMV.$(($KRV-1)) $SRCDIR/linux-$KERNEL
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

sed -i 's/^\(EXTRAVERSION\).*/\1 = '$KEV'/' $SRCDIR/linux-$KERNEL/Makefile
if [[ -f "/boot/config-$KERNEL" ]]; then
	cat /boot/config-$KERNEL > $SRCDIR/linux-$KERNEL/.config
fi
rm -f $SRCDIR/linux
ln -s linux-$KERNEL $SRCDIR/linux
printf "\n${A}Prepared ${I}linux-$KERNEL${N} @ ${A}$SRCDIR${N}\n"

