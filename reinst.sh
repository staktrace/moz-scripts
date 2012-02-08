#!/usr/bin/env bash

FILE=${1-"./fennec-13.0a1.en-US.android-arm.apk"}
if [ ! -f "$FILE" ]; then
    FILE="$HOME/zspace/builds/fennec-13.0a1.en-US.android-arm.apk"
    echo "Falling back to $FILE" > /dev/stderr
    if [ ! -f "$FILE" ]; then
        echo "Error: fallback $FILE not found!" > /dev/stderr
        exit 1;
    fi
else
    echo "Installing $FILE" > /dev/stderr
fi

# adb uninstall org.mozilla.fennec_$USER # not sure what this will do to FF sync, be careful
adb install -r $FILE
