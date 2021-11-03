#
# Makefile for Shortcut FE.
#

obj-$(CONFIG_SHORTCUT_FE) += shortcut-fe.o

ifeq ($(SFE_SUPPORT_IPV6),)
SFE_SUPPORT_IPV6=y
endif
ccflags-$(SFE_SUPPORT_IPV6) += -DSFE_SUPPORT_IPV6

ifdef SFE_SUPPORT_IPV6
obj-$(CONFIG_SHORTCUT_FE) += shortcut-fe-ipv6.o
endif


shortcut-fe-objs := \
	sfe_ipv4.o

ifdef SFE_SUPPORT_IPV6
shortcut-fe-ipv6-objs := \
	sfe_ipv6.o
endif

