#!/bin/bash

set -euo pipefail

LANG=C
umask 0022

ERROR="\e[31m[ERROR]\e[0m"

BINS=(
    helm
    ssh
    virt-install
)

for bin in "${BINS[@]}"
do
    if ! command -v "$bin" > /dev/null
    then
        printf "%b \`%s\` not found in PATH.\n" "$ERROR" "$bin"
        exit 1
    fi
done

trap cleanup EXIT

cleanup() {
    rm -rf "./include.d/$NAME"
}

usage() {
    printf "Usage: %s OPTIONS

Options:
--memory, -m
--name, -n
--os
--size, -s
--help, -h      Help.\n" "$(basename "$0")"
    exit "$1"
}

MEMORY=8192
NAME=
OS=debian13
SIZE=40

while [ "$#" -gt 0 ]
do
    OPT="$1"
    case $OPT in
        -m|--memory) shift ; MEMORY=$1 ;;
        -n|--name) shift ; NAME=$1 ;;
        --os) shift ; OS=$1 ;;
        -s|--size) shift ; SIZE=$1 ;;
        -h|--help) usage 0 ;;
        *) printf "Unknown flag %s\n" "$OPT"; usage 1 ;;
    esac
    shift
done

if [ -z "$NAME" ]
then
    printf "%b Missing name.\n" "$ERROR"
    usage 1
fi

PROJECT_DIR=$(git rev-parse --show-toplevel)
mkdir -p "$PROJECT_DIR/mnt/$NAME/mnt"
chmod 0777 "$PROJECT_DIR/mnt/$NAME/mnt"

initrd_inject=(
    --initrd-inject ./post_install.sh
    --initrd-inject ./preseed.cfg
)
for f in ./include.d/*
do
    [ ! -f "$f" ] && continue
    initrd_inject+=(--initrd-inject "$f")
done

# I *think* that `virt-install` will use the basename of any path to `preseed.cfg`,
# so always look for it in the root in `--extra-args` (`/preseed.cfg`).
virt-install --connect qemu:///system \
    --name "$NAME" \
    --memory "$MEMORY" \
    --extra-args="preseed/file=/preseed.cfg console=ttyS0,115200n8" \
    "${initrd_inject[@]}" \
    --install "$OS" \
    --disk size="$SIZE" \
    --filesystem type=mount,source="$PROJECT_DIR/mnt/$NAME/mnt",target=shared,accessmode=mapped,driver.type=path,driver.wrpolicy=immediate \
    --network bridge=virbr0,model=virtio \
    --graphics none

