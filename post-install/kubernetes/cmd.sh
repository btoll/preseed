#!/bin/bash

set -euo pipefail

LANG=C
umask 0022

j=()
while read -r node
do
    j+=("$node")
done < <(< cluster.json jq --compact-output ".[]")

./install.sh <<< "${j[0]}"

for n in {1..2}
do
    ./install.sh <<< "${j[n]}"
done

