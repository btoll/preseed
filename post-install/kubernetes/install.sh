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

trap cleanup EXIT

cleanup() {
    sudo rm -rf /etc/sudoers.d/passwordless_host
}

parse_templates() {
    local node="$1"
    local name="$(jq --raw-output '.name' <<< "$node")"
    local username="$(jq --raw-output '.username' <<< "$node")"

    mkdir -p "$PROJECT_SHARE/$name/include.d"

    awk -v hostname="$name" \
        -v network_interface="$(jq --raw-output '.network_interface' <<< "$node")" \
        -v ip_address="$(jq --raw-output '.ip_address' <<< "$node")" \
        -v netmask="$(jq --raw-output '.netmask' <<< "$node")" \
        -v gateway="$(jq --raw-output '.gateway' <<< "$node")" \
        -v nameserver="$(jq --raw-output '.nameserver' <<< "$node")" \
        -v full_name="$(jq --raw-output '.full_name' <<< "$node")" \
        -v username="$username" '{
        gsub("HOSTNAME", hostname);
        gsub("NETWORK_INTERFACE", network_interface);
        gsub("IP_ADDRESS", ip_address);
        gsub("NETMASK", netmask);
        gsub("GATEWAY", gateway);
        gsub("NAMESERVER", nameserver);
        gsub("FULL_NAME", full_name);
        gsub("USERNAME", username);
        print
    }' ./tpl/preseed.tpl >| "$PROJECT_SHARE/$name/include.d/preseed.cfg"

    awk -v username="$username" '{
        sub("USERNAME", username);
        print
    }' ./tpl/passwordless_guest.tpl >| "$PROJECT_SHARE/$name/include.d/passwordless_guest"

    if [ "$name" == control-plane ]
    then
        printf "%b Allow sudo temporarily.\n" "$INFO"
        # This `HOSTNAME` is the env var set in the login bash scripts.
        awk -v username="$username" -v hostname="$HOSTNAME" -v project_share="$PROJECT_SHARE" '{
            gsub("USERNAME", username);
            sub("HOSTNAME", hostname);
            gsub("PROJECT_SHARE", project_share);
            print
        }' ./tpl/passwordless_host.tpl | sudo tee /etc/sudoers.d/passwordless_host > /dev/null
    fi
}

DISK=
BLOB=
MEMORY=
NAME=
OS=
PROJECT_SHARE=

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

PROJECT_SHARE="$(git rev-parse --show-toplevel)/post-install/kubernetes/share"

parse_templates "$BLOB"

mkdir -p "$PROJECT_SHARE/$NAME/mnt"
chmod 0777 "$PROJECT_SHARE/$NAME/mnt"

# These are primarily the output of the parsed templates.
initrd_inject=(
    --initrd-inject ./post_install.sh
    --initrd-inject "$PROJECT_SHARE/$NAME/include.d/passwordless_guest"
    --initrd-inject "$PROJECT_SHARE/$NAME/include.d/preseed.cfg"
)
# While these are common to all nodes.
for f in ./include.d/*
do
    [ ! -f "$f" ] && continue
    cp "$f" "$PROJECT_SHARE/$NAME/include.d"
    initrd_inject+=(--initrd-inject "$PROJECT_SHARE/$NAME/include.d/$(basename "$f")")
done

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
    --filesystem type=mount,source="$PROJECT_SHARE/$NAME/mnt",target=shared,accessmode=mapped,driver.type=path,driver.wrpolicy=immediate \
    --network bridge=virbr0,model=virtio \
    --graphics none \
    --noautoconsole \
    --wait=-1
set +x

if [ "$NAME" == control-plane ]
then
    # The ssh command returns a "No route to host" error (255) even though it's state is reported as "running".
    # `virsh -c qemu:///system domstate control-plane`
    # This is brute-ish but it works.
    printf "%b Logging into \`control-plane\` at 192.168.122.100 to run \`kubeadm init\`...\n" "$INFO"
    while ! ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t 192.168.122.100 \
        "sudo kubeadm init --pod-network-cidr=10.244.0.0/16 > /mnt/shared/kubeadm-init.log && sudo cp /etc/kubernetes/admin.conf /mnt/shared/config &> /dev/null"
    do
        sleep 2
    done
    printf "%b \`kubeadm-init.log\` and \`config\` written to \`/mnt/shared/\`.\n" "$INFO"

    mkdir -p "$HOME/.kube"
    sudo cp "$PROJECT_SHARE/$NAME/mnt/config" "$HOME/.kube"
    sudo chown "$USER:$USER" "$HOME/.kube/config"
    printf "%b \`config\` written to \`$HOME/.kube\`.\n" "$INFO"

    # Flannel does not support network policies, it just provides a VXLAN overlay and basic IP allocation.
    # kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    if ! command -v helm > /dev/null
    then
        printf "%b \`helm\` not found in PATH.\n" "$ERROR"
        exit 1
    fi
    helm repo add cilium https://helm.cilium.io/
    helm install cilium cilium/cilium --version 1.20.4 --namespace kube-system

    printf "\n%b Cluster info:\n%s\n" "$INFO" "$(kubectl cluster-info)"
else
    printf "%b Waiting on control-plane initialization...\n" "$INFO"
    while ! sudo grep "kubeadm join" "$PROJECT_SHARE/control-plane/mnt/kubeadm-init.log" &> /dev/null
    do
        sleep 2
    done

    join_cmd=$(sudo sed -n '/kubeadm join/,$p' "$PROJECT_SHARE/control-plane/mnt/kubeadm-init.log")
    printf "%b %s\n" "$INFO" "$join_cmd"

    # Get all the chars after "node" in the var.
    ip_address=192.168.122.$(( 100 + ${NAME##*node} ))

    printf "%b Joining node \`%s\` at %s to control-plane.\n" "$INFO" "$NAME" "$ip_address"
    while ! ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t "$ip_address" "sudo $join_cmd &> /dev/null"
    do
        sleep 2
    done
fi

printf "%b Installation complete.\n" "$SUCCESS"

