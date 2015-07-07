#!/usr/bin/env bash

if [ ! -f "client.mk" ]; then
    echo "Error: no client.mk found; you might be running in the wrong directory!" > /dev/stderr
    exit 1;
fi

if [ ! -d "obj-android" ]; then
    mkdir obj-android
fi

(mach build mobile/android \
    && mach package
) 2>&1 | tee obj-android/build.log
RET=${PIPESTATUS[0]}

exit $RET
