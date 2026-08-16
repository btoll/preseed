#!/bin/bash

set -euo pipefail

LANG=C
umask 0022

INFO="\e[34m[INFO]\e[0m"

if ! command -v virsh > /dev/null
then
    printf "%b Installing \`virsh\`...\n" "$INFO"
    sudo apt-get install virsh -y
fi

for name in control-plane node1 node2
do
    rm -rf "$(git rev-parse --show-toplevel)/post-install/kubernetes/share/$name"
    if [ "$(virsh -c qemu:///system domstate "$name")" == running ]
    then
        virsh -c qemu:///system destroy "$name" 2> /dev/null
    fi
    virsh -c qemu:///system undefine "$name"
    virsh -c qemu:///system vol-delete --pool default "$name.qcow2" 2> /dev/null
done

