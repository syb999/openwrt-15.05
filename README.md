# openwrt-15.05 fast-path 

# backports-mac80211-v5.10
# backports-mt76 support kernel 3.18

sudo apt-get install build-essential asciidoc binutils bzip2 gawk gettext git subversion libssl-dev libncurses5-dev patch unzip zlib1g-dev libc6-dev libbz2-dev gdisk flex

sudo apt-get install libc6:i386 libgcc1:i386 libstdc++5:i386 libstdc++6:i386 libc6-dev-i386

sudo apt-get install libinit

sudo apt-get install python2

# ------------------------------------------------------
# for libiconv
wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.13.1.tar.gz

tar zxvf libiconv-1.13.1.tar.gz && cd libiconv-1.13.1

make && make install

ln -s /usr/local/lib/libiconv.so /usr/lib

ln -s /usr/local/lib/libiconv.so.2 /usr/lib/libiconv.so.2

------- if ERROR (Permission denied) then
./configure --prefix=/usr/local && make

sudo make install && sudo ln -s /usr/local/lib/libiconv.so /usr/lib

sudo ln -s /usr/local/lib/libiconv.so.2 /usr/lib/libiconv.so.2


# ------------------------------------------------------

./scripts/feeds update -a

./scripts/feeds install -a

make menuconfig

make V=99


