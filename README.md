# opemwrt-15.05 fast-path 
# add mt7621-nand success 

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.400000] ------------[ cut here ]------------

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.400000] WARNING: CPU: 0 PID: 552 at /home/syb/0919/openwrt-15.05/build_dir/target-mipsel_1004kc+dsp_uClibc-0.9.33.2/linux-ramips_mt7621-nand/backports-2017-11-01/net/wireless/core.c:789 wiphy_register+0x7c8/0x808 [cfg80211]()

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.420000] Modules linked in: mt7603e(+) mt76 mac80211 cfg80211 compat ip6t_REJECT nf_reject_ipv6 nf_log_ipv6 nf_log_common ip6table_raw ip6table_mangle ip6table_filter ip6_tables x_tables ipv6 shortcut_fe_ipv6 shortcut_fe arc4 crypto_blkcipher leds_gpio xhci_plat_hcd xhci_hcd gpio_button_hotplug usbcore nls_base usb_common

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] CPU: 0 PID: 552 Comm: kmodloader Not tainted 3.18.109 #1

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] Stack : 00000000 00000004 00000006 00000004 00000000 00000000 00000000 00000000

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] 	  803f56da 00000038 00000000 00000000 00000000 8ece0d50 80333544 803a8983

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] 	  00000228 00000000 803f4468 8ece0d50 00000000 8ed6cbb8 8ed6d2f8 8005a420

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] 	  00000001 80028f7c 803acea0 803acea4 80337228 8ec4da6c 8ec4da6c 80333544

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] 	  00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] 	  ...

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] Call Trace:

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<80015e64>] show_stack+0x54/0x88

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<8018fab0>] dump_stack+0x88/0xc0

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<80029084>] warn_slowpath_common+0x84/0xb4

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<8002913c>] warn_slowpath_null+0x18/0x24

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<8ed81410>] wiphy_register+0x7c8/0x808 [cfg80211]

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<8ee80f2c>] ieee80211_register_hw+0x7e4/0xa1c [mac80211]

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<8edc18a8>] mt76_register_device+0x338/0x36c [mt76]

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<8ed79f04>] mt7603_register_device+0x93c/0x988 [mt7603e]

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<8ed78128>] init_module+0x13a128/0x13b330 [mt7603e]

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<801c7ad0>] pci_dev_get+0x1c/0x30

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<801c7bcc>] pci_device_probe+0x68/0xd0

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<801ecf04>] driver_probe_device+0xd8/0x224

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<801ed130>] __driver_attach+0x7c/0xb4

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<801eb2f0>] bus_for_each_dev+0x98/0xa8

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<801ec62c>] bus_add_driver+0x104/0x1ec

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<801ed638>] driver_register+0xb0/0x104

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<8ec3e048>] init_module+0x48/0x78 [mt7603e]

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<8000f238>] do_one_initcall+0x148/0x1ec

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<8007c6f0>] load_module+0x1690/0x1c98

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<8007cdc0>] SyS_init_module+0xc8/0xf4

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] [<800079c8>] handle_sys+0x128/0x14c

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.450000] 

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.610000] ---[ end trace e55f9ce450bd0b85 ]---

Fri Sep 20 06:31:37 2019 kern.warn kernel: [   13.610000] mt7603e: probe of 0000:01:00.0 failed with error -22

Fri Sep 20 06:31:37 2019 kern.info kernel: [   13.620000] mt76x2e 0000:02:00.0: ASIC revision: 76120044

Fri Sep 20 06:31:37 2019 kern.err kernel: [   13.630000] mt76x2e 0000:02:00.0: EEPROM data check failed: 7603

Fri Sep 20 06:31:37 2019 kern.info kernel: [   13.630000] mt76x2e 0000:02:00.0: Invalid MAC address, using random address 
96:57:14:11:f4:44

Fri Sep 20 06:31:37 2019 kern.info kernel: [   13.650000] mt76x2e 0000:02:00.0: ROM patch build: 20141115060606a

Fri Sep 20 06:31:37 2019 kern.info kernel: [   13.660000] mt76x2e 0000:02:00.0: Firmware Version: 0.0.00

Fri Sep 20 06:31:37 2019 kern.info kernel: [   13.670000] mt76x2e 0000:02:00.0: Build: 1

Fri Sep 20 06:31:37 2019 kern.info kernel: [   13.670000] mt76x2e 0000:02:00.0: Build Time: 201507311614____

Fri Sep 20 06:31:37 2019 kern.info kernel: [   13.700000] mt76x2e 0000:02:00.0: Firmware running!



