#!/bin/bash

set -euo pipefail

LANG=C
umask 0022

mkdir -p /mnt/shared
echo "9pnet_virtio" >> /etc/modules
echo "shared  /mnt/shared  9p  trans=virtio,version=9p2000.L,cache=loose  0  0" >> /etc/fstab

git clone https://github.com/vim/vim.git /root/vim
git clone https://github.com/btoll/dotfiles /home/btoll/dotfiles && \
    git clone https://github.com/btoll/weather.git /home/btoll/weather && \
    chown -R btoll:btoll /home/btoll

curl -L https://go.dev/dl/go1.26.5.linux-amd64.tar.gz | tar -xzf - -C /usr/local/

# Compile Vim for YCM support (YCM needs at least vim9.1 with python3 support boo).
pushd /root/vim
make distclean >/dev/null 2>&1 || true
rm -f config.cache
make clean >/dev/null 2>&1 || true
./configure --prefix="/usr/local" --with-features=huge --enable-python3interp
make -j
make install
popd

