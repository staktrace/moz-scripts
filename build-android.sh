#!/usr/bin/env bash

(make -f client.mk \
    && pushd obj-android \
    && make package \
    && popd \
    && cp obj-android/dist/fennec*.apk $HOME/zspace/builds/ \
    && ./save-build
) | tee build.log
