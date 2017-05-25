#!/usr/bin/env bash

MAPFILE=$HOME/Downloads/gecko-mapfile
grep $1 "$MAPFILE"
if [ $? -ne 0 ]; then
    echo "Re-pulling mapfile..." > /dev/stderr
    rm "$MAPFILE" && wget -O "$MAPFILE" --quiet https://api.pub.build.mozilla.org/mapper/gecko-dev/mapfile/full && grep $1 "$MAPFILE"
fi
