#!/bin/bash
# shellcheck disable=2155

set -euo pipefail

LANG=C
umask 0022

ERROR="\e[31m[ERROR]\e[0m"
INFO="\e[34m[INFO]\e[0m"
SUCCESS="\e[32m[SUCCESS]\e[0m"

BINS=(
    ssh
    virt-install
)

for bin in "${BINS[@]}"
do
    if ! command -v "$bin" > /dev/null
    then
        printf "%b Installing \`%s\`...\n" "$INFO" "$bin"
        sudo apt-get install "$bin" -y
    fi
done

parse_templates() {
    local node="$1"

    awk -v hostname="$(jq --raw-output '.name' <<< "$node")" \
        -v network_interface="$(jq --raw-output '.network_interface' <<< "$node")" \
        -v ip_address="$(jq --raw-output '.ip_address' <<< "$node")" \
        -v netmask="$(jq --raw-output '.netmask' <<< "$node")" \
        -v gateway="$(jq --raw-output '.gateway' <<< "$node")" \
        -v nameserver="$(jq --raw-output '.nameserver' <<< "$node")" \
        -v full_name="$(jq --raw-output '.full_name' <<< "$node")" \
        -v username="$(jq --raw-output '.username' <<< "$node")" '{
        gsub("HOSTNAME", hostname);
        gsub("NETWORK_INTERFACE", network_interface);
        gsub("IP_ADDRESS", ip_address);
        gsub("NETMASK", netmask);
        gsub("GATEWAY", gateway);
        gsub("NAMESERVER", nameserver);
        gsub("FULL_NAME", full_name);
        gsub("USERNAME", username);
        print
    }' ./preseed.tpl >| ./preseed.cfg
}

DISK=
BLOB=
MEMORY=
NAME=
OS=

BLOB=$(cat)
if ! printf "%s" "$BLOB" | jq &> /dev/null
then
    printf "%b Invalid JSON.\n" "$ERROR"
    exit 1
fi

NAME="$(jq --raw-output '.name' <<< "$BLOB")"
OS="$(jq --raw-output '.os' <<< "$BLOB")"
MEMORY="$(jq --raw-output '.memory' <<< "$BLOB")"
DISK="$(jq --raw-output '.disk' <<< "$BLOB")"

parse_templates "$BLOB"

mkdir --mode 0777 mnt

# These are primarily the output of the parsed templates.
initrd_inject=(
    --initrd-inject ./post_install.sh
    --initrd-inject ./preseed.cfg
)

# I *think* that `virt-install` will use the basename of any path to `preseed.cfg`,
# so always look for it in the root in `--extra-args` (`/preseed.cfg`).
set -x
virt-install --connect qemu:///system \
    --name "$NAME" \
    --memory "$MEMORY" \
    --extra-args="preseed/file=/preseed.cfg console=ttyS0,115200n8" \
    "${initrd_inject[@]}" \
    --install "$OS" \
    --disk size="$DISK" \
    --filesystem type=mount,source="$(git rev-parse --show-toplevel)/post-install/$NAME/mnt",target=shared,accessmode=mapped,driver.type=path,driver.wrpolicy=immediate \
    --network bridge=virbr0,model=virtio \
    --graphics none \
    --noautoconsole \
    --wait=-1
set +x

printf "%b Installation complete.\n" "$SUCCESS"

