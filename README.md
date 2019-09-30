# openwrt-15.05 fast-path 

sudo apt-get install build-essential asciidoc binutils bzip2 gawk gettext git subversion libssl-dev libncurses5-dev patch unzip zlib1g-dev

sudo apt-get install libc6:i386 libgcc1:i386 libstdc++5:i386 libstdc++6:i386

./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig
make V=99
