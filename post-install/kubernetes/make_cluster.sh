#!/bin/bash

set -euo pipefail

LANG=C
umask 0022

if ! command -v tmux > /dev/null
then
    printf "%b \`tmux\` not found in PATH.\n" "$ERROR"
    exit 1
fi

usage() {
    printf "Usage: %s [OPTIONS]

Options:
--dir, -d      Creates each pane in CWD (optional, defaults to \`pwd\`).
--session, -s  The session name (optional, defaults to current timestamp).
--user, -u     The user name (optional, defaults to USER).

Creates this workspace:

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+ $                            | $                            +
+                              |                              +
+                              |                              +
+                              |                              +
+                              |                              +
+                              |                              +
+                              |                              +
+                              |                              +
+                              |                              +
+-------------------------------------------------------------+
+ $                            | $                            +
+                              |                              +
+                              |                              +
+                              |                              +
+                              |                              +
+                              |                              +
+                              |                              +
+                              |                              +
+                              |                              +
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n" "$0"
    exit "$1"
}

DIR=$(pwd)
SESSION=$(date "+%Y%m%d%H%M%S")

while [ "$#" -gt 0 ]; do
    OPT="$1"
    case $OPT in
        --dir|-d) shift ; DIR=$1 ;;
        --session|-s) shift ; SESSION=$1 ;;
        --help|-help|-h) usage 0 ;;
    esac
    shift
done

if ! tmux has-session -t "$SESSION" 2> /dev/null
then
    tmux new-session -s "$SESSION" -d

    # Open a new pane to its right.
    tmux split-window -h -t "$SESSION"

    # Select first pane before opening another below it.
    tmux select-pane -t 0
    tmux split-window -t "$SESSION"

    # Select top-right pane before opening another below it.
    tmux select-pane -t 2
    tmux split-window -t "$SESSION"

    i=0
    while read -r node
    do
        # The JSON is inserted into a command that another shell parses.
        # Its double quotes can be treated as shell syntax, so encode it first
        # and decode it directly into the `stdin` of `install.sh`.
        node_b64=$(printf '%s' "$node" | base64 | tr -d '\n')
        CMD="cd $DIR && printf '%s' '$node_b64' | base64 -d | ./install.sh"
        tmux send-keys -t "$SESSION":0.$i "$CMD" C-m
        i=$(( i + 1 ))
    done < <(< cluster.json jq --compact-output ".[]")

    tmux send-keys -t "$SESSION":0.3 'cd '"$DIR"' ; clear' C-m

    # Set focus on pane in top-left position.
    tmux select-pane -t 0
fi

tmux attach -t "$SESSION"

