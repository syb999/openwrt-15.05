#
# Copyright (C) 2006-2021 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define KernelPackage/shortcut-fe
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Support
  TITLE:=Kernel driver for FAST Classifier
  DEPENDS:=+kmod-ipv6
  KCONFIG:= \
	CONFIG_SHORTCUT_FE=y \
	CONFIG_SFE_SUPPORT_IPV6=y \
	CONFIG_NF_CONNTRACK_EVENTS=y
  FILES:= \
	$(LINUX_DIR)/net/shortcut-fe/shortcut-fe.ko \
	$(LINUX_DIR)/net/shortcut-fe/shortcut-fe-ipv6.ko
  AUTOLOAD:=$(call AutoLoad,09,shortcut-fe shortcut-fe-ipv6)
endef

define KernelPackage/shortcut-fe/description
Shortcut is an in-Linux-kernel IP packet forwarding engine.
endef

$(eval $(call KernelPackage,shortcut-fe))


define KernelPackage/fast-classifier
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Support
  TITLE:=Kernel driver for FAST Classifier
  DEPENDS:=+kmod-ipv6 +kmod-ipt-conntrack +kmod-shortcut-fe +kmod-ipt-conntrack-extra
  KCONFIG:= \
	CONFIG_FAST_CLASSIFIER=y \
	CONFIG_SFE_SUPPORT_IPV6=y \
	CONFIG_NF_CONNTRACK_CHAIN_EVENTS=y
  FILES:= \
	$(LINUX_DIR)/net/fast-classifier/fast-classifier.ko
  AUTOLOAD:=$(call AutoLoad,15,fast-classifier)
endef

define KernelPackage/fast-classifier/description
FAST Classifier talks to SFE to make decisions about offloading connections.
endef

$(eval $(call KernelPackage,fast-classifier))
