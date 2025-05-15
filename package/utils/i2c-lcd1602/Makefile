include $(TOPDIR)/rules.mk

PKG_NAME:=i2c-lcd1602
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/i2c-lcd1602
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=I2C LCD1602 Log Monitor
  DEPENDS:=+libi2c
endef

define Package/i2c-lcd1602/description
  A log monitoring tool that displays content on I2C LCD1602 display.
endef

ifdef CONFIG_USE_UCLIBC
  TARGET_CFLAGS += -std=gnu99
endif

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
    $(TARGET_CC) $(TARGET_CFLAGS) \
        -I$(PKG_BUILD_DIR) \
        -I$(STAGING_DIR)/usr/include \
        -I$(LINUX_DIR)/include \
        -L$(STAGING_DIR)/usr/lib -li2c \
        -o $(PKG_BUILD_DIR)/i2c_lcd1602 \
        $(PKG_BUILD_DIR)/i2c_lcd1602.c
endef

define Package/i2c-lcd1602/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/i2c_lcd1602 $(1)/usr/bin/
endef

$(eval $(call BuildPackage,i2c-lcd1602))
