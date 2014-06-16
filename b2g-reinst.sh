#!/usr/bin/env bash

if [ ! -d "objdir-gecko" ]; then
    echo "Error: no objdir-gecko found!" > /dev/stderr
    exit 1
fi

adb remount
adb push objdir-gecko/dist/b2g/libxul.so /system/b2g/libxul.so
adb shell stop b2g
adb shell start b2g
