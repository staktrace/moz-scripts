#!/usr/bin/env bash

if [ ! -f "client.mk" ]; then
    echo "Error: no client.mk found; you might be running in the wrong directory!" > /dev/stderr
    exit 1;
fi

if [ ! -d "obj-android" ]; then
    mkdir obj-android
fi;

(jscheck mobile/android/chrome/content/browser.js \
    && make -C obj-android/toolkit/xre \
    && pushd obj-android \
    && make package \
    && popd \
    && cp obj-android/dist/fennec*.apk $HOME/zspace/builds/
) 2>&1 | tee obj-android/build.log

exit ${PIPESTATUS[0]}
