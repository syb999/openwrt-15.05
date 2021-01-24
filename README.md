# openwrt-15.05 fast-path 

# backports-mac80211-v5.4
# backports-mt76 support kernel 3.18

sudo apt-get install build-essential asciidoc binutils bzip2 gawk gettext git subversion libssl-dev libncurses5-dev patch unzip zlib1g-dev libc6-dev libbz2-dev

sudo apt-get install libc6:i386 libgcc1:i386 libstdc++5:i386 libstdc++6:i386 libc6-dev-i386

./scripts/feeds update -a

./scripts/feeds install -a

make menuconfig

make V=99


