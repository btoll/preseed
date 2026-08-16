#!/bin/bash

set -exuo pipefail

LANG=C
umask 0022

while [ "$#" -gt 0 ]
do
    OPT="$1"
    case $OPT in
        -h|--help) usage 0 ;;
        *) printf "Unknown flag %s\n" "$OPT"; usage 1 ;;
    esac
    shift
done

mkdir -p /mnt/shared
echo "9pnet_virtio" >> /etc/modules
echo "shared  /mnt/shared  9p  trans=virtio,version=9p2000.L,cache=none  0  0" >> /etc/fstab

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

swapoff --all
sed -i '/ swap / s/^/#/' /etc/fstab

modprobe overlay
modprobe br_netfilter

cat << EOF > /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat << EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's GPG key (containerd is maintained by Docker).
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bookworm stable" \
    > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y containerd.io

# Generate default config and enable it.
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key | gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubeadm kubectl kubelet

# Hold them at current version (prevent auto-upgrade).
apt-mark hold kubeadm kubectl kubelet

systemctl enable kubelet

