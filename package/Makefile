#
# Copyright (C) 2006-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

curdir:=package

include $(INCLUDE_DIR)/rootfs.mk

-include $(TMP_DIR)/.packagedeps
$(curdir)/builddirs:=$(sort $(package-) $(package-y) $(package-m))
$(curdir)/builddirs-install:=.
$(curdir)/builddirs-default:=. $(sort $(package-y) $(package-m))
$(curdir)/builddirs-prereq:=. $(sort $(prereq-y) $(prereq-m))
ifneq ($(IGNORE_ERRORS),)
  package-y-filter := $(package-y)
  package-m-filter := $(filter-out $(package-y),$(package-m))
  package-n-filter := $(filter-out $(package-y) $(package-m),$(package-))
  package-ignore-errors := $(filter n m y,$(IGNORE_ERRORS))
  package-ignore-errors := $(if $(package-ignore-errors),$(package-ignore-errors),n m)
  $(curdir)/builddirs-ignore-download := $(foreach m,$(package-ignore-errors),$(package-$(m)-filter))
  $(curdir)/builddirs-ignore-compile := $(foreach m,$(package-ignore-errors),$(package-$(m)-filter))
endif

PACKAGE_INSTALL_FILES:= \
	$(foreach pkg,$(sort $(package-y)), \
		$(foreach variant, \
			$(if $(strip $(package/$(pkg)/variants)), \
				$(package/$(pkg)/variants), \
				$(if $(package/$(pkg)/default-variant), \
					$(package/$(pkg)/default-variant), \
					default \
				) \
			), \
			$(PKG_INFO_DIR)/$(lastword $(subst /,$(space),$(pkg))).$(variant).install \
		) \
	)

$(curdir)/cleanup: $(TMP_DIR)/.build
	rm -rf $(STAGING_DIR_ROOT)

$(curdir)/install: $(TMP_DIR)/.build
	- find $(STAGING_DIR_ROOT) -type d | $(XARGS) chmod 0755
	rm -rf $(TARGET_DIR)
	[ -d $(TARGET_DIR)/tmp ] || mkdir -p $(TARGET_DIR)/tmp
	@$(FIND) `sed -e 's|.*|$(PACKAGE_DIR)$(if $(CONFIG_PER_FEED_REPO),/*)/&_*.ipk|' $(PACKAGE_INSTALL_FILES)` | sort -u | $(OPKG) install
	@for file in $(PACKAGE_INSTALL_FILES); do \
		[ -s $$file.flags ] || continue; \
		for flag in `cat $$file.flags`; do \
			$(OPKG) flag $$flag < $$file; \
		done; \
	done || true
	@-$(MAKE) package/preconfig
	$(prepare_rootfs)

PASSOPT=""
PASSARG=""
ifndef CONFIG_OPKGSMIME_PASSPHRASE
  ifneq ($(call qstrip,$(CONFIG_OPKGSMIME_PASSFILE)),)
    PASSOPT="-passin"
    PASSARG="file:$(call qstrip,$(CONFIG_OPKGSMIME_PASSFILE))"
  endif
endif

PACKAGE_SUBDIRS=.
ifneq ($(CONFIG_PER_FEED_REPO),)
  ifneq ($(CONFIG_PER_FEED_REPO_ADD_DISABLED),)
    PACKAGE_SUBDIRS=base kernel $(FEEDS_AVAILABLE)
  else
    PACKAGE_SUBDIRS=base kernel $(FEEDS_ENABLED)
  endif
endif

$(curdir)/index: FORCE
	@echo Generating package index...
	@for d in $(PACKAGE_SUBDIRS); do ( \
		mkdir -p $(PACKAGE_DIR)/$$d; \
		cd $(PACKAGE_DIR)/$$d || continue; \
		$(SCRIPT_DIR)/ipkg-make-index.sh . 2>&1 > Packages && \
			gzip -9nc Packages > Packages.gz; \
	); done
ifdef CONFIG_SIGNED_PACKAGES
	@echo Signing package index...
	@for d in $(PACKAGE_SUBDIRS); do ( \
		[ -d $(PACKAGE_DIR)/$$d ] && \
			cd $(PACKAGE_DIR)/$$d || continue; \
		$(STAGING_DIR_HOST)/bin/usign -S -m Packages -s $(BUILD_KEY); \
	); done
else
ifeq ($(call qstrip,$(CONFIG_OPKGSMIME_KEY)),)
	@echo Signing key has not been configured
else
ifeq ($(call qstrip,$(CONFIG_OPKGSMIME_CERT)),)
	@echo Certificate has not been configured
else
	@echo Signing package index...
	@for d in $(PACKAGE_SUBDIRS); do ( \
		[ -d $(PACKAGE_DIR)/$$d ] && \
			cd $(PACKAGE_DIR)/$$d || continue; \
		openssl smime -binary -in Packages.gz \
			-out Packages.sig -outform PEM -sign \
			-signer $(CONFIG_OPKGSMIME_CERT) \
			-inkey $(CONFIG_OPKGSMIME_KEY) \
			$(PASSOPT) $(PASSARG); \
	); done
endif
endif
endif

$(curdir)/preconfig:

$(curdir)/flags-install:= -j1

$(eval $(call stampfile,$(curdir),package,prereq,.config))
$(eval $(call stampfile,$(curdir),package,cleanup,$(TMP_DIR)/.build))
$(eval $(call stampfile,$(curdir),package,compile,$(TMP_DIR)/.build))
$(eval $(call stampfile,$(curdir),package,install,$(TMP_DIR)/.build))

$(eval $(call subdir,$(curdir)))
