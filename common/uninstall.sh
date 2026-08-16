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

# Yes, this is assuming that `node.json` is in the cwd, and it's valid json with a `.name`.
# Also, it assumes that the name of the cluster is the same as that of the project directory.
NAME="$(< node.json jq --raw-output '.name')"
rm -rf "$(git rev-parse --show-toplevel)/post-install/$NAME/vm"
if [ "$(virsh -c qemu:///system domstate "$NAME")" == running ]
then
    virsh -c qemu:///system destroy "$NAME" 2> /dev/null
fi
virsh -c qemu:///system undefine "$NAME"
virsh -c qemu:///system vol-delete --pool default "$NAME.qcow2" 2> /dev/null

