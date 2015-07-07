#!/usr/bin/env bash

ssh people "grep $1 gecko-mapfile"
if [ $? -ne 0 ]; then
    echo "Re-pulling mapfile..." > /dev/stderr
    ssh people "rm gecko-mapfile && wget -O gecko-mapfile --quiet https://api.pub.build.mozilla.org/mapper/gecko-dev/mapfile/full && grep $1 gecko-mapfile"
fi
