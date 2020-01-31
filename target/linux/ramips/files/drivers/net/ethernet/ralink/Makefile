#
# Makefile for the Ralink SoCs built-in ethernet macs
#

mtk-eth-soc-y					+= mtk_eth_soc.o ethtool.o

mtk-eth-soc-$(CONFIG_NET_RALINK_MDIO)		+= mdio.o
mtk-eth-soc-$(CONFIG_NET_RALINK_MDIO_RT2880)	+= mdio_rt2880.o
mtk-eth-soc-$(CONFIG_NET_RALINK_MDIO_MT7620)	+= mdio_mt7620.o

mtk-eth-soc-$(CONFIG_NET_RALINK_RT288X)	+= soc_rt2880.o
mtk-eth-soc-$(CONFIG_NET_RALINK_RT305X)	+= soc_rt3050.o
mtk-eth-soc-$(CONFIG_NET_RALINK_RT3883)	+= soc_rt3883.o
mtk-eth-soc-$(CONFIG_NET_RALINK_MT7620)	+= soc_mt7620.o
mtk-eth-soc-$(CONFIG_NET_RALINK_MT7621)	+= soc_mt7621.o

obj-$(CONFIG_NET_RALINK_ESW_RT3052)		+= esw_rt3050.o
obj-$(CONFIG_NET_RALINK_GSW_MT7620)		+= gsw_mt7620.o mt7530.o
obj-$(CONFIG_NET_RALINK_GSW_MT7621)		+= gsw_mt7621.o mt7530.o
obj-$(CONFIG_NET_RALINK)			+= mtk-eth-soc.o
