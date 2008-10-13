REV        := 1
INITRD     := --initrd

ifeq ($(shell id -u),0)
LINUX      := /usr/src/linux
MODULE_LOC := /usr/src/modules
MODULE_CLN := make-kpkg --rootcmd fakeroot modules_clean
else
LINUX      := $(CURDIR)/linux
MODULE_LOC := $(CURDIR)/modules
MODULE_CLN := fakeroot make-kpkg modules_clean
endif

export LANG=C
export LC_ALL=C

PUSHLINUX := cd $(LINUX) &&
MAKE_KPKG := make-kpkg --rootcmd fakeroot --revision $(REV) $(INITRD) --us --uc
CONFIGURE := $(MAKE_KPKG) configure

.PHONY: all
all: fast

.PHONY: clean
clean: modules_clean
	$(PUSHLINUX) $(MAKE_KPKG) $(@)

.PHONY: buildpackage
buildpackage: clean oldconfig
	$(PUSHLINUX) $(MAKE_KPKG) $(@) modules

.PHONY: fast
fast: clean oldconfig
	$(PUSHLINUX) $(MAKE_KPKG) kernel_image kernel_headers modules

.PHONY: modules_clean
modules_clean:
	-$(PUSHLINUX) $(MODULE_CLN) $(@)

.PHONY: modules
modules: modules_clean
	$(PUSHLINUX) $(MAKE_KPKG) $(@)

.PHONY: oldconfig
oldconfig:
	if [ ! -f $(LINUX)/.config ] && [ -r /proc/config.gz ]; then \
		zcat /proc/config.gz > $(LINUX)/.config; \
	fi
	$(PUSHLINUX) $(MAKE) $(@)
	$(PUSHLINUX) $(CONFIGURE)

.PHONY: config
config: oldconfig
	$(PUSHLINUX) $(MAKE) $(@)
	$(PUSHLINUX) $(CONFIGURE)

.PHONY: menuconfig
menuconfig: oldconfig
	$(PUSHLINUX) $(MAKE) $(@)
	$(PUSHLINUX) $(CONFIGURE)

.PHONY: xconfig
xconfig: oldconfig
	$(PUSHLINUX) $(MAKE) $(@)
	$(PUSHLINUX) $(CONFIGURE)
