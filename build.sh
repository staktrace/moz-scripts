#!/usr/bin/env bash

(make -f client.mk && pushd obj-android && make package && popd && scp obj-android/dist/fennec*.apk kgupta-air:) | tee build.log
