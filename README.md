# openwrt-15.05 fast-path 

# backports-mac80211-v5.10
# backports-mt76 support kernel 3.18

sudo apt-get install build-essential asciidoc binutils bzip2 gawk gettext git subversion libssl-dev libncurses5-dev patch unzip zlib1g-dev libc6-dev libbz2-dev gdisk flex libinit python2

sudo apt-get install libc6:i386 libgcc1:i386 libstdc++5:i386 libstdc++6:i386 libc6-dev-i386

# ------------------------------------------------------
# for libiconv
wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.13.1.tar.gz2

tar zxvf libiconv-1.13.1.tar.gz && cd libiconv-1.13.1

make && make install

ln -s /usr/local/lib/libiconv.so /usr/lib

ln -s /usr/local/lib/libiconv.so.2 /usr/lib/libiconv.so.2
# ------------------------------------------------------

./scripts/feeds update -a

./scripts/feeds install -a

make menuconfig

make V=99


