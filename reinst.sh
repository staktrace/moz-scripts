#!/usr/bin/env bash

VERSION=32
FILE=${1-"./fennec-$VERSION.0a1.en-US.android-arm.apk"}
if [ ! -f "$FILE" ]; then
    FILE=$(ls -t1 $HOME/zspace/builds/fennec-*.apk | head -1)
    echo "Falling back to $FILE" > /dev/stderr
    if [ ! -f "$FILE" ]; then
        echo "Error: fallback $FILE not found!" > /dev/stderr
        exit 1;
    fi
    FOUND=${FILE##*/}
    if [ ${FOUND:0:9} != "fennec-$VERSION" ]; then
        echo "Warning: found ${FOUND:0:9}; this doesn't match expected version of fennec-$VERSION; $0 may need to be updated!"
    fi
else
    echo "Installing $FILE" > /dev/stderr
fi

# adb uninstall org.mozilla.fennec_$USER # not sure what this will do to FF sync, be careful
adb install -r $FILE
