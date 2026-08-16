#!/bin/bash

set -euo pipefail

LANG=C
umask 0022

ERROR="\e[31m[ERROR]\e[0m"
#INFO="\e[34m[INFO]\e[0m"
#SUCCESS="\e[32m[SUCCESS]\e[0m"

SCRIPTNAME=$(basename "$0")

usage() {
    printf "Usage: %s [OPTIONS]

Options:
--dir, -d   The name of the directory.
--help, -h  Help.\n" "$SCRIPTNAME"
    exit "$1"
}

DIR=

while [ "$#" -gt 0 ]
do
    OPT="$1"
    case $OPT in
        --dir|-d) shift ; DIR=$1 ;;
        -h|--help) usage 0 ;;
        *) printf "Unknown flag %s\n" "$OPT"; usage 1 ;;
    esac
    shift
done

if [ -z "$DIR" ]
then
    printf "%b DIR cannot be empty.\n" "$ERROR"
    usage 1
fi

PROJECT="post-install/$DIR"

if [ -d "$PROJECT" ]
then
    printf "%b DIR \`%s\` already exists.\n" "$ERROR" "$DIR"
    exit 1
fi

mkdir -p "$PROJECT"

for f in ./include.d/*
do
    cp "$f" "$PROJECT"
    printf "%b Copied %s into ./%s\n" "$INFO" "$f" "$PROJECT"
done

