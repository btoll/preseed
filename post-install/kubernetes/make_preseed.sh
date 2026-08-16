#!/bin/bash

make_preseed() {
    local ip_address="$1"
    local node="$2"
    local username="$3"

    mkdir -p "./include.d/$node"

    awk -v ip="$ip_address" -v host="$node" -v user="$username" '{
        gsub("IP_ADDRESS", ip);
        gsub("HOSTNAME", host);
        gsub("USERNAME", user);
        print
    }' ./tpl/preseed.tpl >| "./include.d/$node/preseed.cfg"
}

