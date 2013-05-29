#!/usr/bin/env bash

if [ ! -f "client.mk" ]; then
    echo "Error: no client.mk found; you might be running in the wrong directory!" > /dev/stderr
    exit 1;
fi

if [ ! -d "obj-gonk" ]; then
    echo "Error: no obj-gonk found!" > /dev/stderr
fi

echo "$(date +%s) BEGIN $0" >> $HOME/Documents/buildtimes.log

(make -C obj-gonk/toolkit/library libs \
    && make -C obj-gonk package
) 2>&1 | tee obj-gonk/build.log
RET=${PIPESTATUS[0]}

echo "$(date +%s) END $0" >> $HOME/Documents/buildtimes.log
exit $RET
