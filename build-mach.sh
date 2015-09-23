#!/usr/bin/env bash

if [ ! -f "client.mk" ]; then
    echo "Error: no client.mk found; you might be running in the wrong directory!" > /dev/stderr
    exit 1;
fi

mach build $* 2>&1 | tee build.log
RET=${PIPESTATUS[0]}

exit $RET
