#!/usr/bin/env bash

MAPFILE=$HOME/Downloads/gecko-mapfile
grep $1 "$MAPFILE"
if [ $? -ne 0 ]; then
    echo "Re-pulling mapfile..." > /dev/stderr
    rm -f "$MAPFILE" && wget -O "$MAPFILE" --quiet https://mapper.mozilla-releng.net/gecko-dev/mapfile/since/2018-01-01 && grep $1 "$MAPFILE"
fi
