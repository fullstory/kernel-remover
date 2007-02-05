REV=1
LANG=C
INITRD="--initrd"
ifeq ($(shell id -u),0)
	BASE_DIR="/usr/src"
	MODULE_LOC="/usr/src/modules"
else
	BASE_DIR=$(shell pwd)
	MODULE_LOC="${BASE_DIR}/modules"
endif
export LANG REV BASE_DIR MODULE_LOC

.PHONY: all
all:	fast

.PHONY: clean-modules
clean-modules:
ifeq ($(shell id -u),0)
	-cd ${BASE_DIR}/linux && \
		make-kpkg modules_clean
else
	-cd ${BASE_DIR}/linux && \
		fakeroot make-kpkg modules_clean
endif

.PHONY: clean
clean: clean-modules
	cd ${BASE_DIR}/linux && \
		make-kpkg --rootcmd fakeroot clean

.PHONY: source
source: clean oldconfig
	cd ${BASE_DIR}/linux && \
		make-kpkg --rootcmd fakeroot --revision ${REV} ${INITRD} --us --uc buildpackage modules

.PHONY: fast
fast: clean oldconfig
	cd ${BASE_DIR}/linux && \
		make-kpkg --rootcmd fakeroot --revision ${REV} ${INITRD} --us --uc kernel_image kernel_headers kernel_doc modules

.PHONY: realfast
realfast: clean oldconfig
	cd ${BASE_DIR}/linux && \
		make-kpkg --rootcmd fakeroot --revision ${REV} ${INITRD} --us --uc kernel_image modules

.PHONY: no-doc
no-doc: clean oldconfig
	cd ${BASE_DIR}/linux && \
		make-kpkg --rootcmd fakeroot --revision ${REV} ${INITRD} --us --uc kernel_image kernel_headers modules kernel_source

.PHONY: modules
modules: clean-modules
	cd ${BASE_DIR}/linux && \
		make-kpkg --rootcmd fakeroot --revision ${REV} modules

.PHONY: oldconfig
oldconfig:
	[ ! -f ${BASE_DIR}/linux/.config -a -r /proc/config.gz ] && zcat /proc/config.gz > ${BASE_DIR}/linux/.config || true
	cd ${BASE_DIR}/linux && \
		make oldconfig  && \
		make-kpkg --rootcmd fakeroot --revision ${REV} configure

.PHONY: config
config: oldconfig
	cd ${BASE_DIR}/linux && \
		make config && \
		make-kpkg --rootcmd fakeroot --revision ${REV} configure

.PHONY: menuconfig
menuconfig: oldconfig
	cd ${BASE_DIR}/linux && \
		make menuconfig && \
		make-kpkg --rootcmd fakeroot --revision ${REV} configure

.PHONY: xconfig
xconfig: oldconfig
	cd ${BASE_DIR}/linux && \
		make xconfig && \
		make-kpkg --rootcmd fakeroot --revision ${REV} configure

.PHONY: gconfig
gconfig: oldconfig
	cd ${BASE_DIR}/linux && \
		make gconfig && \
		make-kpkg --rootcmd fakeroot --revision ${REV} configure

.PHONY: prep-sidux-modules
prep-sidux-modules:
	[ -x /usr/bin/unp-kernel-modules ] && \
		cd ${BASE_DIR} && \
			/usr/bin/unp-kernel-modules

.PHONY: sidux-modules
sidux-modules: prep-sidux-modules modules

.PHONY: pack-modules
pack-modules: clean-modules
	[ -d ${BASE_DIR}/modules ] && \
		cd ${BASE_DIR} && \
			rm -f kernel-`ls -ld ${BASE_DIR}/linux | sed s/.*linux-//`-custom-modules.tar.bz2 && \
			tar -cjf kernel-`ls -ld ${BASE_DIR}/linux | sed s/.*linux-//`-custom-modules.tar.bz2 modules/

.PHONY: pack-patches
pack-patches:
	[ -d ${BASE_DIR}/patches ] && \
		cd ${BASE_DIR} && \
			rm -f kernel-`ls -ld ${BASE_DIR}/linux | sed s/.*linux-//`-custom-patches.tar.bz2 && \
			tar -cjf kernel-`ls -ld ${BASE_DIR}/linux | sed s/.*linux-//`-custom-patches.tar.bz2 patches

.PHONY: pack
pack: pack-patches pack-modules

.PHONY: zip
zip:
	cd ${BASE_DIR}/ && \
		rm -f kernel-`ls -ld ${BASE_DIR}/linux | sed s/.*linux-//`.zip
		for i in /usr/share/sidux-kernelhacking/scripts/*.sh; do \
			sed s/\%KERNEL_VERSION\%/`ls -ld ${BASE_DIR}/linux | sed s/.*linux-//`/g $$i > ${BASE_DIR}/`basename $$i` && \
			chmod +x ${BASE_DIR}/`basename $$i`; \
		done && \
		sed -i s/^\#\%STATIC_VERSION\%/STATIC_VERSION=\"`ls -ld ${BASE_DIR}/linux | sed s/.*linux-//`\"\\t\#\%STATIC_VERSION\%/ *-source.sh; \
		zip	kernel-`ls -ld ${BASE_DIR}/linux | sed s/.*linux-//`.zip \
				*`ls -ld ${BASE_DIR}/linux | sed s/.*linux-//`*.deb \
				*-source.sh kernel-`ls -ld ${BASE_DIR}/linux | sed s/.*linux-//`-custom-patches.{zip,tar\.gz,tar\.bz2} \
				kernel-`ls -ld ${BASE_DIR}/linux | sed s/.*linux-//`-custom-modules.{zip,tar\.gz,tar\.bz2} \
				`find /usr/share/sidux-kernelhacking/scripts/*.sh -exec basename {} \; | xargs`

.PHONY: release
release: all zip

