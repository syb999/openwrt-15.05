
sf-ts-y += sf_ts.o sf_ts_genl.o sf_ts_hash.o sf_qos.o
ifdef CONFIG_SF_PKT_SEND_BY_KERNEL
sf-ts-y += sf_pkt_by_kernel.o
else
sf-ts-y += sf_pkt_by_user.o
endif
obj-$(CONFIG_SIFLOWER_TS) += sf-ts.o
