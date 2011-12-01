#!/usr/bin/env bash

(make -C obj-android/mobile/android \
    && pushd obj-android \
    && make package \
    && popd \
    && cp obj-android/dist/fennec*.apk ~/zspace/builds/
) | tee build.log
