#!/bin/bash
# requires:	- bash >= 2.05b
#		- wget
#		- patch
# licensed under the GPL2
###############################################################################

# user settings
WGET_OPTIONS="-qNc"
#WGET_OPTIONS="-Nc"
PATCH_VERBOSITY="--silent"
KERNELMIRROR="http://zeus2.kernel.org/pub/linux/kernel"
#KERNELMIRROR="http://www.de.kernel.org/pub/linux/kernel"
#KERNELMIRROR="http://www.uk.kernel.org/sites/ftp.kernel.org/pub/linux/kernel"
NAME="`getent passwd $(id -u) | cut -d\: -f1`"
#DEF_CPU="-up"
VER="$(wget -qO- http://zeus2.kernel.org/kdist/finger_banner | grep "^The latest stable version of the Linux kernel is:" | cut -d\: -f2 | sed s/[[:space:]]//g)"		# let's be boring and stable
#VER="$(wget -qO- http://zeus2.kernel.org/kdist/finger_banner | grep "^The latest snapshot for the stable Linux kernel tree is:" | cut -d\: -f2 | sed s/[[:space:]]//g)"	# -git nostrum quotidianum da nobis hodie
#VER="2.6.20.2"
#VER="2.6.20.4-rc1"
#VER="2.6.20-rc7-git4"
REVISION="1"

#%STATIC_VERSION%

case ${VER} in
	2.6.20*)
		PATCH[1]="http://gaugusch.at/acpi-dsdt-initrd-patches/acpi-dsdt-initrd-v0.8.3-2.6.20.patch"
		PATCH[2]="http://sidux.com/files/patches/t-sinus_111card-2.6.16.diff"
		PATCH[3]="http://sidux.com/files/patches/2.6.20-at76c503a20070307.diff.bz2"
		PATCH[4]="$KERNELMIRROR/people/akpm/patches/2.6/2.6.20-rc6/2.6.20-rc6-mm3/broken-out/2.6-sony_acpi4.patch"
		PATCH[5]="$KERNELMIRROR/people/akpm/patches/2.6/2.6.20-rc6/2.6.20-rc6-mm3/broken-out/pl2303-willcom-ws002in-support.patch"
		PATCH[6]="$KERNELMIRROR/people/akpm/patches/2.6/2.6.21-rc3/2.6.21-rc3-mm2/broken-out/gregkh-driver-nozomi.patch"
		;;
	2.6.21*)
		PATCH[1]="http://gaugusch.at/acpi-dsdt-initrd-patches/acpi-dsdt-initrd-v0.8.3-2.6.20.patch"
		PATCH[2]="http://sidux.com/files/patches/t-sinus_111card-2.6.16.diff"
		PATCH[5]="http://sidux.com/files/patches/2.6.20-at76c503a20070307.diff.bz2"
		;;
	*)
		# generic kernel, not supported
		wget $WGET_OPTIONS "$KERNELMIRROR/v$KV/linux-$VER.tar.bz2"
		rm -rf "linux-$VER"
		tar -xjf "linux-$VER.tar.bz2" 2> /dev/null
		echo "unsupported kernel, abort abnormally!"
		exit 1
		;;
esac

###############################################################################

# determine DEF_CPU
CPU=$(dpkg-architecture -qDEB_BUILD_GNU_CPU)
case ${CPU} in
	i386|i486)
		ARCH=""
		[[ -z $DEF_CPU ]] && DEF_CPU="-smp"
		;;
	x86_64)
		ARCH="64"
		[[ -z $DEF_CPU ]] && DEF_CPU="-smp"
		;;
	*)
		ARCH=${CPU}
		[[ -z $DEF_CPU ]] && DEF_CPU="-smp"
		;;
esac

# parse necessary info
VER="${VER}-${NAME}${ARCH}${DEF_CPU}-${REVISION}"
[ -n "$STATIC_VERSION" ] && VER="$STATIC_VERSION"
VAR=(${VER/-/ })
EV="-${VAR[1]}"
VAR=(${VAR[0]//./ })
STABLE="${VAR[3]}"
KV=${VAR[0]}.${VAR[1]}
[[ ${VER} == *-rc[1-9]* ]] && MV=${KV}.$((${VAR[2]}-1)) || MV=${KV}.${VAR[2]}
RMV=${KV}.${VAR[2]}
RC=$(grep -o rc[0-9]* <<<"${EV//-/ }")
GIT=$(grep -o git[0-9]* <<<"${EV//-/ }")
[[ -n $STABLE && -z $RC ]] && EV=".$STABLE$EV"
if [[ -n $STABLE && -n $RC ]]; then
	MV=${KV}.${VAR[2]}
	EV=".$STABLE$EV"
	STABLE=$((${STABLE}-1))
fi

# determine $BASE_DIR
if [[ $(id -u) != 0 ]]; then
	BASE_DIR="$(pwd)"
	PATCH_DIR="${BASE_DIR}/patches"
	DPKG_PATCH_DIR="${BASE_DIR}/linux-custom-patches-${VER}-1"
else
	BASE_DIR="/usr/src"
	PATCH_DIR=${BASE_DIR}
	DPKG_PATCH_DIR="${BASE_DIR}/linux-custom-patches-${VER}-1"
fi

# purely debugging purposes
debug_parser()
{
	echo "VER=$VER"
	echo "VAR=$VAR"
	echo "MV=$MV"
	echo "RMV=$RMV"
	echo "KV=$KV"
	echo "EV=$EV"
	echo "STABLE=$STABLE"
	echo "RC=$RC"
	echo "GIT=$GIT"
	DEBUG="yes"
}

# <!-- functions adapted from kelmo
patch_it()
{
	case ${1} in
		*.gz)
			zcat ${1} | patch ${2} &>/dev/null
			;;
		*.bz2)
			bzcat ${1} | patch ${2} &>/dev/null
			;;
		*)
			patch ${2} < ${1} &>/dev/null
			;;
	esac
}

do_patch()
{
	if patch_it ${1} "-p1 --force --dry-run $PATCH_VERBOSITY"; then
		patch_it ${1} "${PATCH_VERBOSITY} -p1"
		ZIPME="$ZIPME ${1}"
		echo "OK"
	elif patch_it ${1} "-p0 --force --dry-run $PATCH_VERBOSITY"; then
		patch_it ${1} "${PATCH_VERBOSITY} -p0"
		ZIPME="$ZIPME ${1}"
		echo "OK"
	else
		echo "FAILED"
		exit 4
	fi
}
# -->

clean_up()
{
	# clean up
	echo "   > clean up, please wait"
	rm -rf	"${BASE_DIR}/linux-$VER" \
		"${BASE_DIR}/linux-$MV" \
		"$DPKG_PATCH_DIR"
}

fetch_upstream_tarball()
{
	echo "   > download the upstream kernel and patches"
	
	pushd ${BASE_DIR} &>/dev/null
		echo -ne "\t* downloading linux-$MV.tar.bz2 . . . "
		UPSTREAM_KERNEL="$KERNELMIRROR/v$KV/linux-$MV.tar.bz2"
		wget $WGET_OPTIONS "$UPSTREAM_KERNEL"

		if [[ -f linux-$MV.tar.bz2 ]]; then
			echo "OK"
		
			# unpack kernel tarball
			echo -ne "\t   - unpacking linux-$MV.tar.bz2 . . . "
			tar -xjf "linux-$MV.tar.bz2" || exit 2
			mv "linux-$MV" "linux-$VER"
			echo "OK"
		else
			echo "FAILED"
			exit 2
		fi
	popd &>/dev/null
}

fetch_and_apply_upstream_patches()
{
	echo "   > fetch and apply upstream kernel patches"
	UPSTREAM_PATCHES=""
	[[ -n $STABLE && ! $STABLE = 0 ]] &&            UPSTREAM_PATCHES="$UPSTREAM_PATCHES $KERNELMIRROR/v$KV/patch-$MV.$STABLE.bz2"

	if [[ -n $STABLE && -n $RC ]]; then
		STABLERC_PATCH=""
		for i in "$KERNELMIRROR/people/chrisw/stable/" "$KERNELMIRROR/people/gregkh/stable/" "$KERNELMIRROR/v$KV/testing/"; do
			for j in bz2 gz; do
				if wget --spider -q "$i/patch-$MV.$(($STABLE + 1))-$RC.$j"; then
					STABLERC_PATCH="$i/patch-$MV.$(($STABLE + 1))-$RC.$j"
					break
				fi
			done
			[ -n "$STABLERC_PATCH" ] && break
		done

		if [ -n "$STABLERC_PATCH" ]; then
			UPSTREAM_PATCHES="$UPSTREAM_PATCHES $STABLERC_PATCH"
			STABLERC_PATCH=""
			unset STABLERC_PATCH
		else
			echo "ERROR: no -stable patch available!"
			exit 99
		fi
	fi

	[[ -z $RC && -n $GIT && -z $STABLE ]] &&	UPSTREAM_PATCHES="$UPSTREAM_PATCHES $KERNELMIRROR/v$KV/snapshots/patch-$RMV-$GIT.bz2"
	[[ -n $RC && -z $STABLE ]] &&			UPSTREAM_PATCHES="$UPSTREAM_PATCHES $KERNELMIRROR/v$KV/testing/patch-$RMV-$RC.bz2"
	[[ -n "$RC" && -n $GIT && -z $STABLE ]] &&	UPSTREAM_PATCHES="$UPSTREAM_PATCHES $KERNELMIRROR/v$KV/snapshots/patch-$RMV-$RC-$GIT.bz2"

	mkdir -p ${PATCH_DIR}
	pushd ${PATCH_DIR} &>/dev/null
		for i in $UPSTREAM_PATCHES; do
			P_ARR=(${i//\// })
			set -- "${P_ARR[@]}"
			P_FILE=${!#}

			echo -ne "\t* downloading ${P_FILE} . . . "
			wget $WGET_OPTIONS ${i}
			if [[ -f ${P_FILE} ]]; then
				echo "OK"
				pushd "${BASE_DIR}/linux-$VER" &>/dev/null
					echo -ne "\t\t+ patching with ${P_FILE} . . . "
					do_patch ${PATCH_DIR}/${P_FILE}
				popd &>/dev/null
			else
				echo "FAILED"
				exit 3
			fi
		done
	popd &>/dev/null
}

# <!-- functions adapted from kelmo
fetch_and_apply_patches()
{
	if [[ ${PATCH[@]} ]]; then
		echo "   > fetch and apply custom patches"

		for P in ${PATCH[@]}; do
			# put url into array with -d/, patch name is last element
			P_ARR=(${P//\// })
			set -- "${P_ARR[@]}"
			P_FILE=${!#}
			echo -ne "\t* downloading ${P_FILE} . . . "

			# get patch
			mkdir -p ${PATCH_DIR}
			pushd ${PATCH_DIR} &>/dev/null
				wget ${WGET_OPTIONS} ${P}
				if [[ -f ${P_FILE} ]]; then
					echo "OK"
				else
					echo "FAILED"
					continue
				fi
			popd &>/dev/null

			echo -ne "\t\t+ patching with ${P_FILE} . . . "
			pushd ${BASE_DIR}/linux-${VER} &>/dev/null
				do_patch ${PATCH_DIR}/${P_FILE}
			popd &>/dev/null
		done
	fi
}
# functions adapted from kelmo -->

dpkg_patches()
{
	[[ "ZIPME" ]] || return
	[[ -n $DPKG_PATCH_DIR ]] || return
	[[ -x $(type -p dpkg-buildpackage) ]] || return
	[[ -x $(type -p fakeroot) ]] || return
	
	echo "   > create linux-custom-patches-${VER}_1_$(dpkg-architecture -qDEB_BUILD_ARCH).deb for custom patches"
	
	mkdir -p "$DPKG_PATCH_DIR"
	cp -r /usr/share/sidux-kernelhacking/linux-custom-patches/* "$DPKG_PATCH_DIR/"

	for i in ${DPKG_PATCH_DIR}/debian/*; do
		sed -i "s/\%VER\%/${VER}/g;\
			s/\%REVISION\%/1/g;\
			s/\%DEBFULLNAME\%/${DEBFULLNAME}/g;\
			s/\%DEBEMAIL\%/${DEBEMAIL}/g;\
			s/\%DATE\%/$(date --rfc-2822)/g" "$i"
	done

	# create debian/copyright
	for i in $UPSTREAM_KERNEL $UPSTREAM_PATCHES ${PATCH[@]}; do
		sed -i "s|\%PATCH_LIST\%|${i}\\n\\t\%PATCH_LIST\%|" "${DPKG_PATCH_DIR}/debian/copyright"
	done
	sed -i '/\%PATCH_LIST\%/d' "${DPKG_PATCH_DIR}/debian/copyright"

	cp "$0" "$DPKG_PATCH_DIR/linux-source-$VER.sh"
	chmod +x "$DPKG_PATCH_DIR/linux-source-$VER.sh"

	mkdir -p "$DPKG_PATCH_DIR/patches"
	for i in $ZIPME; do
		cp "$i" "$DPKG_PATCH_DIR/patches/"
	done

	pushd "$DPKG_PATCH_DIR" &>/dev/null
		echo -ne "\t* dpkg-buildpackage . . . "
		fakeroot dpkg-buildpackage -uc -us &> /dev/null
		if [ "$?" -eq 0 ]; then
			echo "`du -ah ../linux-custom-patches-${VER}_1_$(dpkg-architecture -qDEB_BUILD_ARCH).deb | sed s/[[:space:]].*//` OK"
		else
			echo "FAILED"
		fi
		
		rm -f ../linux-custom-patches-${VER}*.{dsc,changes,tar.gz}
	popd &>/dev/null
	[ ! "$DEBUG" = "yes" ] && rm -rf "${DPKG_PATCH_DIR}"
}

zip_patches()
{
	[[ $ZIPME ]] || return
	echo "   > create kernel-$VER-custom-patches.zip for custom patches"
	pushd ${BASE_DIR} &>/dev/null
		rm -f "${BASE_DIR}/kernel-$VER-custom-patches.zip"
		zip "kernel-$VER-custom-patches.zip" `echo $ZIPME | sed s%${BASE_DIR}/%%g` | sed s/[[:space:]]adding\:/\\t\ \ \ -\ adding\:/g
		echo -e "\t             $(du -ah "kernel-$VER-custom-patches.zip" | awk '{print $1}' 2>/dev/null)"
	popd &>/dev/null
}

enable_libata()
{
	if [ -f "${BASE_DIR}/linux-$VER/drivers/scsi/libata-core.c" ]; then
		echo "   > enable libata for ATAPI devices"
		perl -pi -e 's|int atapi_enabled = 0;|int atapi_enabled = 1;|' "${BASE_DIR}/linux-$VER/drivers/scsi/libata-core.c"
	fi
}

set_extraversion()
{
	echo "   > set EXTRAVERSION"
	perl -pi -e "s/^(EXTRAVERSION).*/\1 = ${EV}/" "${BASE_DIR}/linux-$VER/Makefile"
}

fixup_source()
{
	echo "   > prepare source for existing kernel"
	[ -f "/boot/config-$VER" ] && cp "/boot/config-$VER" "${BASE_DIR}/linux-$VER/.config"
}

linkup_source()
{
	rm -rf "${BASE_DIR}/linux"
	ln -s "linux-$VER" ${BASE_DIR}/linux
}



####################
## int main(void) ##
####################

ZIPME=""
echo "### start linux-$VER ###"
#debug_parser
#exit 0
clean_up
fetch_upstream_tarball
fetch_and_apply_upstream_patches
fetch_and_apply_patches
dpkg_patches
#zip_patches
#enable_libata
set_extraversion
fixup_source
linkup_source
echo "### linux-$VER finished ###"

exit 0

