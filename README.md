# openwrt-15.05 fast-path 

# backports-mac80211 from openwrt-19.07
# backports-mt76 support kernel 3.18

sudo apt-get install build-essential asciidoc binutils bzip2 gawk gettext git subversion libssl-dev libncurses5-dev patch unzip zlib1g-dev

sudo apt-get install libc6:i386 libgcc1:i386 libstdc++5:i386 libstdc++6:i386

./scripts/feeds update -a

./scripts/feeds install -a

patch -p1 < 01-rssi-luci.patch

patch -p1 < 02-80211rw-luci.patch

patch -p1 < 03-igmp-luci.patch

patch -p1 < 04-fix-wget.patch

patch -p1 < 05-mtd-backup-luci.patch

patch -p1 < 06-openvpn-luci.patch

patch -p1 < 07-dnscachesize-luci.patch

patch -p1 < 08-libssh2.patch

patch -p1 < 09-asterisk1.8.patch

make menuconfig

make V=99


