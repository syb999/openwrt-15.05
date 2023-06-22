include $(TOPDIR)/rules.mk

PKG_NAME:=docker
PKG_VERSION:=18.09.6

include $(INCLUDE_DIR)/package.mk

define Package/docker
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Docker Community Edition
  URL:=https://www.docker.com/
  DEPENDS:=+btrfs-progs +libdevmapper +libnetwork +tini +ca-certificates +iptables-mod-extra \
           +DOCKER_SECCOMP:libseccomp +kmod-ikconfig +kmod-veth +kmod-br-netfilter +kmod-nf-conntrack-netlink \
           +kmod-nf-ipvs +kmod-nf-nat +libpthread
  USERID:=docker:docker
  MENU:=1
endef

define Package/docker/description
  Docker Engine is used by millions enables containerized applications
  to run anywhere consistently on any infrastructure.
endef


ifeq ($(ARCH),arm)
	DOCKER_ARCH:=armel
endif

ifeq ($(ARCH),x86_64)
	DOCKER_ARCH:=x86_64
endif

PKG_SOURCE_URL:=https://download.docker.com/linux/static/stable/$(DOCKER_ARCH)/
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tgz

UNTAR_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

define Build/Prepare
	mkdir -vp $(UNTAR_DIR)
	tar -zxvf $(DL_DIR)/$(PKG_SOURCE) -C $(UNTAR_DIR)
endef

define Build/Compile
endef

define Package/docker/install
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(UNTAR_DIR)/docker/docker $(1)/usr/bin/docker
	$(INSTALL_BIN) $(UNTAR_DIR)/docker/dockerd $(1)/usr/bin/
	$(INSTALL_BIN) $(UNTAR_DIR)/docker/docker-init $(1)/usr/bin/
	$(INSTALL_BIN) $(UNTAR_DIR)/docker/docker-proxy $(1)/usr/bin/
	$(INSTALL_BIN) $(UNTAR_DIR)/docker/containerd $(1)/usr/bin/
	$(INSTALL_BIN) $(UNTAR_DIR)/docker/containerd-shim $(1)/usr/bin/
	$(INSTALL_BIN) $(UNTAR_DIR)/docker/ctr $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/usr/sbin/
	$(CP) $(UNTAR_DIR)/docker/runc $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/opt/docker/
	$(INSTALL_DIR) $(1)/usr/share/docker/
	$(INSTALL_BIN) ./files/check-config.sh $(1)/usr/share/docker/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/dockerd.init $(1)/etc/init.d/dockerd

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/dockerd $(1)/etc/config/dockerd

	#$(INSTALL_DIR) $(1)/htdocs/luci-static/resources/dockerman

	# Must be after systcl 11-br-netfilter.conf from kmod-br-netfilter
	#$(INSTALL_DIR) $(1)/etc/sysctl.d
	#$(INSTALL_DATA) ./files/etc/sysctl.d/sysctl-br-netfilter-ip.conf \
		#$(1)/etc/sysctl.d/12-br-netfilter-ip.conf
endef

define Package/dockerd/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] || {
	/etc/init.d/dockerd enable
	/etc/init.d/dockerd uciadd
	/etc/init.d/dockerd start
}
endef

define Package/dockerd/prerm
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] || {
	/etc/init.d/dockerd disable
	/etc/init.d/dockerd stop
	/etc/init.d/dockerd ucidel
}
endef

$(eval $(call BuildPackage,docker))
