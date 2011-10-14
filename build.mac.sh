#!/usr/bin/env bash

(make -f client.mk && pushd obj-android && make package && popd && cp obj-android/dist/fennec*.apk ~/) | tee build.log
