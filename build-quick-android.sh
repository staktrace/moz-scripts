#!/usr/bin/env bash

if [ ! -f "client.mk" ]; then
    echo "Error: no client.mk found; you might be running in the wrong directory!" > /dev/stderr
    exit 1;
fi

if [ ! -d "obj-android" ]; then
    mkdir obj-android
fi;

(make -C obj-android/mobile/android \
    && pushd obj-android \
    && make package \
    && popd \
    && cp obj-android/dist/fennec*.apk $HOME/zspace/builds/
) | tee obj-android/build.log
