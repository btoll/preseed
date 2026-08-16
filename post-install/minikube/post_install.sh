#!/bin/bash
# shellcheck disable=1091

set -euo pipefail

LANG=C
umask 0022

mkdir -p /mnt/shared
echo "9pnet_virtio" >> /etc/modules
echo "shared  /mnt/shared  9p  trans=virtio,version=9p2000.L,cache=loose  0  0" >> /etc/fstab

git clone https://github.com/vim/vim.git /root/vim
git clone https://github.com/btoll/dotfiles /home/btoll/dotfiles && \
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

# Docker
apt-get remove "$(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc | cut -f1)"
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
dpkg -i minikube_latest_amd64.deb

#minikube kubectl -- get pods -A
#usermod -aG docker "$USER"
#newgrp docker

