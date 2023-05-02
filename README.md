# openwrt-15.05 fast-path 

# backports-mac80211-v5.10
# backports-mt76 support kernel 3.18

sudo apt-get install build-essential asciidoc binutils bzip2 gawk gettext git subversion libssl-dev libncurses5-dev patch unzip zlib1g-dev libc6-dev libbz2-dev gdisk flex python3-distutils

sudo apt-get install libc6:i386 libgcc1:i386 libstdc++5:i386 libstdc++6:i386 libc6-dev-i386

sudo apt-get install intltool

sudo apt-get install tk-dev libffi-dev liblzma-dev libreadline-dev libsqlite3-dev

For python3.6+,we can use pyenv:

git clone https://github.com/pyenv/pyenv.git ~/.pyenv

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc

echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc

echo 'eval "$(pyenv init -)"' >> ~/.bashrc

exec $SHELL -l

pyenv install 3.9.10 -v

pyenv rehash

pyenv global 3.9.10


# ------------------------------------------------------
# for libiconv
wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.13.1.tar.gz

tar zxvf libiconv-1.13.1.tar.gz && cd libiconv-1.13.1

./configure --prefix=/usr/local

make

sudo make install

sudo make install && sudo ln -s /usr/local/lib/libiconv.so /usr/lib

sudo ln -s /usr/local/lib/libiconv.so.2 /usr/lib/libiconv.so.2

# ------------------------------------------------------

./scripts/feeds update -a

./scripts/feeds install -a

make menuconfig

make V=99


