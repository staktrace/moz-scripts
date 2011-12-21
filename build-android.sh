#!/usr/bin/env bash

if [ ! -f "client.mk" ]; then
    echo "Error: no client.mk found; you might be running in the wrong directory!" > /dev/stderr
    exit 1;
fi

if [ ! -d "obj-android" ]; then
    mkdir obj-android
fi;

(make -f client.mk \
    && pushd obj-android \
    && make package \
    && popd \
    && cp obj-android/dist/fennec*.apk $HOME/zspace/builds/ \
    && save-build
) 2>&1 | tee obj-android/build.log
