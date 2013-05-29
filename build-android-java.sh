#!/usr/bin/env bash

if [ ! -f "client.mk" ]; then
    echo "Error: no client.mk found; you might be running in the wrong directory!" > /dev/stderr
    exit 1;
fi

if [ ! -d "obj-android" ]; then
    mkdir obj-android
fi

echo "$(date +%s) BEGIN $0" >> $HOME/Documents/buildtimes.log

(make -C obj-android/mobile/android \
    && make -C obj-android package \
    && cp obj-android/dist/fennec*.apk $HOME/zspace/builds/
) 2>&1 | tee obj-android/build.log
RET=${PIPESTATUS[0]}

echo "$(date +%s) END $0" >> $HOME/Documents/buildtimes.log
exit $RET
